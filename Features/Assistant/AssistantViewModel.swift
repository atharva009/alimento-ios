//
//  AssistantViewModel.swift
//  Alimento
//
//  Created on Phase 8
//

import Foundation
import SwiftData
import Combine

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var state: AssistantState = .idle
    @Published var showingConfirmation = false
    @Published var pendingToolCall: PendingToolCall?
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let modelContext: ModelContext
    private let aiService: AIService
    private let toolRegistry: ToolRegistry
    private let jsonGuard: JSONGuard?
    private let geminiClient: GeminiClient?
    
    enum AssistantState {
        case idle
        case thinking
        case executingTool
        case waitingForConfirmation
    }
    
    struct PendingToolCall {
        let requestId: String
        let tool: String
        let args: [String: AnyCodable]
        let confirmationMessage: String?
    }
    
    init(
        modelContext: ModelContext,
        aiService: AIService,
        toolRegistry: ToolRegistry,
        jsonGuard: JSONGuard?,
        geminiClient: GeminiClient?
    ) {
        self.modelContext = modelContext
        self.aiService = aiService
        self.toolRegistry = toolRegistry
        self.jsonGuard = jsonGuard
        self.geminiClient = geminiClient
        
        // Add welcome message
        addSystemMessage("Hello! I'm your meal planning assistant. I can help you manage your inventory, plan meals, and generate grocery lists. What would you like to do?")
    }
    
    func sendUserMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard state == .idle else { return }
        
        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        
        // Process message
        Task {
            await processUserMessage(text)
        }
    }
    
    func confirmToolCall() {
        guard let pending = pendingToolCall else { return }
        
        showingConfirmation = false
        state = .executingTool
        
        Task {
            await executeToolCall(pending)
        }
    }
    
    func cancelToolCall() {
        showingConfirmation = false
        pendingToolCall = nil
        state = .idle
        
        addAssistantMessage("Action cancelled.")
    }
    
    // MARK: - Private Methods
    
    private func addSystemMessage(_ text: String) {
        let message = ChatMessage(role: .system, content: text)
        messages.append(message)
    }
    
    private func addAssistantMessage(_ text: String) {
        let message = ChatMessage(role: .assistant, content: text)
        messages.append(message)
    }
    
    private func processUserMessage(_ text: String) async {
        state = .thinking
        
        do {
            // Build context
            let context = buildContext()
            
            // Build prompt
            let userPrompt = text
            let systemInstruction = AssistantPromptBuilder.buildSystemInstruction()
            let contextPrompt = AssistantPromptBuilder.buildContextPrompt(
                userProfile: context.userProfile,
                inventorySummary: context.inventorySummary,
                plannedMealsSummary: context.plannedMealsSummary,
                groceryListSummary: context.groceryListSummary
            )
            
            let fullPrompt = "\(contextPrompt)\n\nUser message: \(userPrompt)"
            
            // Get response from AI
            guard let jsonGuard = jsonGuard, let client = geminiClient else {
                // Fallback when backend is not configured
                addAssistantMessage("AI features require the backend proxy. Configure BackendConfig.baseURL and run the backend server.")
                state = .idle
                return
            }
            
            let responseText = try await client.generateContent(
                prompt: fullPrompt,
                systemInstruction: systemInstruction
            )
            
            // Decode response
            let response: AssistantResponse = try await jsonGuard.fetchJSON(
                schemaDescription: buildResponseSchema(),
                modelType: AssistantResponse.self,
                primaryPrompt: fullPrompt,
                systemInstruction: systemInstruction
            )
            
            // Handle response
            switch response.type {
            case .message:
                addAssistantMessage(response.content ?? "I'm here to help!")
                state = .idle
                
            case .toolCall:
                guard let tool = response.tool,
                      let requestId = response.requestId,
                      let args = response.args else {
                    addAssistantMessage("Invalid tool call format.")
                    state = .idle
                    return
                }
                
                // Validate tool call
                do {
                    try toolRegistry.validateToolCall(tool: tool, args: args)
                } catch {
                    addAssistantMessage("Invalid tool call: \(error.localizedDescription)")
                    state = .idle
                    return
                }
                
                // Check if confirmation required
                if response.confirmationRequired == true {
                    pendingToolCall = PendingToolCall(
                        requestId: requestId,
                        tool: tool,
                        args: args,
                        confirmationMessage: response.confirmationMessage
                    )
                    showingConfirmation = true
                    state = .waitingForConfirmation
                } else {
                    // Execute immediately
                    state = .executingTool
                    await executeToolCall(PendingToolCall(
                        requestId: requestId,
                        tool: tool,
                        args: args,
                        confirmationMessage: nil
                    ))
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            state = .idle
        }
    }
    
    private func executeToolCall(_ pending: PendingToolCall) async {
        do {
            // Build execution context
            let context = buildToolExecutionContext()
            
            // Execute tool
            let result = try await toolRegistry.executeTool(
                tool: pending.tool,
                args: pending.args,
                context: context
            )
            
            // Create tool result
            let toolResult = ToolResult(
                requestId: pending.requestId,
                tool: pending.tool,
                success: true,
                result: result
            )
            
            // Send result back to AI for final message
            await sendToolResultToAI(toolResult)
            
        } catch {
            // Create error result
            let toolResult = ToolResult(
                requestId: pending.requestId,
                tool: pending.tool,
                success: false,
                error: error.localizedDescription
            )
            
            // Send error result to AI
            await sendToolResultToAI(toolResult)
        }
    }
    
    private func sendToolResultToAI(_ toolResult: ToolResult) async {
        do {
            guard let jsonGuard = jsonGuard, let client = geminiClient else {
                addAssistantMessage("Tool executed, but cannot generate response without backend.")
                state = .idle
                return
            }
            
            let prompt = AssistantPromptBuilder.buildToolResultPrompt(toolResult: toolResult)
            let systemInstruction = AssistantPromptBuilder.buildSystemInstruction()
            
            let responseText = try await client.generateContent(
                prompt: prompt,
                systemInstruction: systemInstruction
            )
            
            let response: AssistantResponse = try await jsonGuard.fetchJSON(
                schemaDescription: buildResponseSchema(),
                modelType: AssistantResponse.self,
                primaryPrompt: prompt,
                systemInstruction: systemInstruction
            )
            
            if response.type == .message {
                addAssistantMessage(response.content ?? "Action completed.")
            } else {
                addAssistantMessage("Action completed.")
            }
            
            state = .idle
            pendingToolCall = nil
            
        } catch {
            addAssistantMessage("Action completed, but couldn't generate response: \(error.localizedDescription)")
            state = .idle
            pendingToolCall = nil
        }
    }
    
    private func buildContext() -> (userProfile: UserProfile?, inventorySummary: [AssistantInventorySummary], plannedMealsSummary: [AssistantPlannedMealSummary], groceryListSummary: AssistantGroceryListSummary?) {
        // Fetch user profile
        let userProfileDescriptor = FetchDescriptor<UserProfile>()
        let userProfile = try? modelContext.fetch(userProfileDescriptor).first
        
        // Fetch inventory summary
        let inventoryDescriptor = FetchDescriptor<InventoryItem>()
        let inventoryItems = (try? modelContext.fetch(inventoryDescriptor)) ?? []
        let inventorySummary = inventoryItems.map { item in
            AssistantInventorySummary(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                location: item.location,
                expiryDate: item.expiryDate
            )
        }
        
        // Fetch planned meals summary
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        
        let mealsDescriptor = FetchDescriptor<PlannedMeal>(
            predicate: #Predicate<PlannedMeal> { meal in
                meal.date >= weekStart && meal.date < weekEnd
            }
        )
        let plannedMeals = (try? modelContext.fetch(mealsDescriptor)) ?? []
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        let plannedMealsSummary = plannedMeals.map { meal in
            AssistantPlannedMealSummary(
                date: formatter.string(from: meal.date),
                mealType: meal.mealType,
                title: meal.title
            )
        }
        
        // Fetch grocery list summary
        let groceryDescriptor = FetchDescriptor<GroceryList>()
        let groceryLists = (try? modelContext.fetch(groceryDescriptor)) ?? []
        let activeList = groceryLists.first
        
        let groceryListSummary: AssistantGroceryListSummary? = activeList.map { list in
            let items = list.items ?? []
            let topItems = Array(items.prefix(5)).compactMap { ($0 as? GroceryItem)?.name }
            return AssistantGroceryListSummary(
                itemCount: items.count,
                topItems: topItems
            )
        }
        
        return (userProfile, inventorySummary, plannedMealsSummary, groceryListSummary)
    }
    
    private func buildToolExecutionContext() -> ToolExecutionContext {
        let servicesContainer = ServicesContainer(modelContext: modelContext)
        
        let userProfileDescriptor = FetchDescriptor<UserProfile>()
        let userProfile = try? modelContext.fetch(userProfileDescriptor).first
        
        return ToolExecutionContext(
            modelContext: modelContext,
            inventoryService: servicesContainer.inventoryService,
            dishLogService: servicesContainer.dishLogService,
            plannerService: servicesContainer.plannerService,
            groceryService: servicesContainer.groceryService,
            userProfile: userProfile
        )
    }
    
    private func buildResponseSchema() -> String {
        return """
        {
          "type": "message" | "toolCall",
          "content": "string (required if type is message)",
          "tool": "string (required if type is toolCall)",
          "args": { ... } (required if type is toolCall),
          "requestId": "string (required if type is toolCall, must be UUID)",
          "confirmationRequired": boolean (optional),
          "confirmationMessage": "string (optional)"
        }
        """
    }
}

