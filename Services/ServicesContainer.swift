//
//  ServicesContainer.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData
import SwiftUI
import Combine

/// Container for all services, providing dependency injection
@MainActor
final class ServicesContainer: ObservableObject {
    
    let inventoryService: InventoryService
    let dishLogService: DishLogService
    let plannerService: PlannerService
    let groceryService: GroceryService
    let aiService: AIService
    let seedDataService: SeedDataService
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Initialize services in dependency order
        self.inventoryService = InventoryServiceImpl(modelContext: modelContext)
        self.dishLogService = DishLogServiceImpl(
            modelContext: modelContext,
            inventoryService: inventoryService
        )
        self.plannerService = PlannerServiceImpl(modelContext: modelContext)
        self.groceryService = GroceryServiceImpl(
            modelContext: modelContext,
            inventoryService: inventoryService,
            plannerService: plannerService
        )
        self.aiService = AIServiceImpl()
        self.seedDataService = SeedDataService(
            modelContext: modelContext,
            inventoryService: inventoryService,
            dishLogService: dishLogService,
            plannerService: plannerService
        )
    }
    
    /// Creates an AssistantViewModel using this container's services and AI client.
    func makeAssistantViewModel() -> AssistantViewModel {
        let config = AIConfiguration.shared
        var jsonGuard: JSONGuard?
        var geminiClient: GeminiClient?
        if config.mode == .live, let backendURL = try? config.getBackendBaseURL() {
            geminiClient = GeminiClient(backendBaseURL: backendURL)
            jsonGuard = geminiClient.map { JSONGuard(client: $0) }
        }
        let toolRegistry = Self.createToolRegistry()
        return AssistantViewModel(
            modelContext: modelContext,
            aiService: aiService,
            toolRegistry: toolRegistry,
            jsonGuard: jsonGuard,
            geminiClient: geminiClient,
            servicesContainer: self
        )
    }
    
    private static func createToolRegistry() -> ToolRegistry {
        let executors: [ToolName: ToolExecutor] = [
            .addInventoryItem: AddInventoryItemExecutor(),
            .updateInventoryQuantity: UpdateInventoryQuantityExecutor(),
            .createPlannedMeal: CreatePlannedMealExecutor(),
            .generateGroceryList: GenerateGroceryListExecutor(),
            .logCookedDish: LogCookedDishExecutor()
        ]
        return ToolRegistry(executors: executors)
    }
}
