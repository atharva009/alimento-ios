//
//  AssistantPromptBuilder.swift
//  Alimento
//
//  Created on Phase 8
//

import Foundation

final class AssistantPromptBuilder {
    static func buildSystemInstruction() -> String {
        return """
        You are a helpful meal planning assistant for the Alimento app. You help users manage their pantry, plan meals, and generate grocery lists.
        
        IMPORTANT: You must respond ONLY using one of these JSON envelope formats:
        
        1. Plain message (when no action is needed):
        {
          "type": "message",
          "content": "Your response text here"
        }
        
        2. Tool call (when user requests an action):
        {
          "type": "toolCall",
          "tool": "toolName",
          "args": { ... },
          "requestId": "unique-uuid-string",
          "confirmationRequired": false,
          "confirmationMessage": "optional message"
        }
        
        RULES:
        - Always use the envelope format. Never respond with plain text or markdown.
        - For toolCall, requestId must be a unique UUID string.
        - Only use toolCall when the user explicitly requests an action.
        - If itemId is required but not provided, ask a clarifying question using a message envelope.
        - Prefer using titles over dishId unless dishId is clearly known from context.
        - Set confirmationRequired: true for potentially large or important changes.
        
        AVAILABLE TOOLS:
        
        1. addInventoryItem
        Adds an item to inventory.
        Args: { name: string, category?: string, quantity: number, unit: string, location: "pantry"|"fridge"|"freezer", expiryDate?: "YYYY-MM-DD" }
        
        2. updateInventoryQuantity
        Updates inventory item quantity.
        Args: { itemId: string (UUID), delta: number (positive to add, negative to subtract) }
        Note: If itemId is unknown, ask user to clarify which item.
        
        3. createPlannedMeal
        Creates a planned meal.
        Args: { date: "YYYY-MM-DD", mealType: "breakfast"|"lunch"|"dinner"|"snack", title?: string, dishId?: string (UUID) }
        Note: Either title or dishId must be provided.
        
        4. generateGroceryList
        Generates a grocery list.
        Args: { daysAhead: number (1-14), includePlannedMeals: boolean, includeLowStock: boolean }
        
        5. logCookedDish
        Logs a cooked dish and decrements inventory.
        Args: { name: string, servings: number, dateCooked: "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM:SS", ingredientsUsed: [{ inventoryItemId: string (UUID), quantity: number, unit: string }] }
        Note: If inventoryItemId is unknown, ask user to clarify.
        
        SAFETY:
        - Never invent itemIds or dishIds. Ask if missing.
        - Validate all inputs before calling tools.
        - Use confirmationRequired for important changes.
        """
    }
    
    static func buildContextPrompt(
        userProfile: UserProfile?,
        inventorySummary: [AssistantInventorySummary],
        plannedMealsSummary: [AssistantPlannedMealSummary],
        groceryListSummary: AssistantGroceryListSummary?
    ) -> String {
        var context = "Current app context:\n\n"
        
        // User profile (non-sensitive)
        if let profile = userProfile {
            context += "User preferences:\n"
            if !profile.dietaryPreference.isEmpty {
                context += "- Dietary preference: \(profile.dietaryPreference)\n"
            }
            if !profile.allergies.isEmpty {
                context += "- Allergies: \(profile.allergies.joined(separator: ", "))\n"
            }
            context += "\n"
        }
        
        // Inventory summary (compact)
        if !inventorySummary.isEmpty {
            context += "Current inventory (\(inventorySummary.count) items):\n"
            for item in inventorySummary.prefix(10) {
                context += "- \(item.name): \(item.quantity) \(item.unit) (\(item.location))"
                if let expiry = item.expiryDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    context += ", expires: \(formatter.string(from: expiry))"
                }
                context += "\n"
            }
            if inventorySummary.count > 10 {
                context += "... and \(inventorySummary.count - 10) more items\n"
            }
            context += "\n"
        }
        
        // Planned meals summary
        if !plannedMealsSummary.isEmpty {
            context += "Planned meals this week:\n"
            for meal in plannedMealsSummary.prefix(7) {
                context += "- \(meal.date): \(meal.mealType) - \(meal.title)\n"
            }
            context += "\n"
        }
        
        // Grocery list summary
        if let grocery = groceryListSummary {
            context += "Active grocery list: \(grocery.itemCount) items"
            if !grocery.topItems.isEmpty {
                context += " (top items: \(grocery.topItems.prefix(3).joined(separator: ", ")))"
            }
            context += "\n"
        }
        
        return context
    }
    
    static func buildToolResultPrompt(toolResult: ToolResult) -> String {
        let resultJson = try! JSONEncoder().encode(toolResult)
        let resultString = String(data: resultJson, encoding: .utf8) ?? "{}"
        
        return """
        A tool was executed with the following result:
        
        \(resultString)
        
        Please respond with a user-friendly message explaining what happened. Use the message envelope format:
        {
          "type": "message",
          "content": "Your explanation here"
        }
        
        If the tool succeeded, confirm the action in a friendly way.
        If the tool failed, explain the error clearly and suggest what the user can do.
        """
    }
}

// MARK: - Supporting Types

struct AssistantInventorySummary {
    let name: String
    let quantity: Double
    let unit: String
    let location: String
    let expiryDate: Date?
}

struct AssistantPlannedMealSummary {
    let date: String
    let mealType: String
    let title: String
}

struct AssistantGroceryListSummary {
    let itemCount: Int
    let topItems: [String]
}

