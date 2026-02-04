//
//  ToolRegistry.swift
//  Alimento
//
//  Created on Phase 8
//

import Foundation
import SwiftData

enum ToolName: String, Codable, CaseIterable {
    case addInventoryItem
    case updateInventoryQuantity
    case createPlannedMeal
    case generateGroceryList
    case logCookedDish
}

// MARK: - Tool Argument Schemas

struct AddInventoryItemArgs: Decodable {
    let name: String
    let category: String?
    let quantity: Double
    let unit: String
    let location: String
    let expiryDate: String?
    
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ToolValidationError.invalidArgument("name", "Name cannot be empty")
        }
        guard quantity > 0 else {
            throw ToolValidationError.invalidArgument("quantity", "Quantity must be greater than zero")
        }
        guard !unit.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ToolValidationError.invalidArgument("unit", "Unit cannot be empty")
        }
        let allowedLocations = ["pantry", "fridge", "freezer"]
        guard allowedLocations.contains(location.lowercased()) else {
            throw ToolValidationError.invalidArgument("location", "Location must be one of: pantry, fridge, freezer")
        }
    }
}

struct UpdateInventoryQuantityArgs: Decodable {
    let itemId: String
    let delta: Double
    
    func validate() throws {
        guard delta != 0 else {
            throw ToolValidationError.invalidArgument("delta", "Delta cannot be zero")
        }
    }
}

struct CreatePlannedMealArgs: Decodable {
    let date: String
    let mealType: String
    let title: String?
    let dishId: String?
    
    func validate() throws {
        // Validate date format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard formatter.date(from: date) != nil else {
            throw ToolValidationError.invalidArgument("date", "Date must be in ISO format (YYYY-MM-DD)")
        }
        
        let allowedMealTypes = ["breakfast", "lunch", "dinner", "snack"]
        guard allowedMealTypes.contains(mealType.lowercased()) else {
            throw ToolValidationError.invalidArgument("mealType", "Meal type must be one of: breakfast, lunch, dinner, snack")
        }
        
        let hasTitle = title != nil && !title!.trimmingCharacters(in: .whitespaces).isEmpty
        let hasDishId = dishId != nil && !dishId!.trimmingCharacters(in: .whitespaces).isEmpty
        
        guard hasTitle || hasDishId else {
            throw ToolValidationError.invalidArgument("title/dishId", "Either title or dishId must be provided")
        }
    }
}

struct GenerateGroceryListArgs: Decodable {
    let daysAhead: Int
    let includePlannedMeals: Bool
    let includeLowStock: Bool
    
    func validate() throws {
        guard daysAhead >= 1 && daysAhead <= 14 else {
            throw ToolValidationError.invalidArgument("daysAhead", "Days ahead must be between 1 and 14")
        }
    }
}

struct LogCookedDishArgs: Decodable {
    let name: String
    let servings: Int
    let dateCooked: String
    let ingredientsUsed: [IngredientUsage]
    
    struct IngredientUsage: Decodable {
        let inventoryItemId: String
        let quantity: Double
        let unit: String
    }
    
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ToolValidationError.invalidArgument("name", "Dish name cannot be empty")
        }
        guard servings >= 1 else {
            throw ToolValidationError.invalidArgument("servings", "Servings must be at least 1")
        }
        guard !ingredientsUsed.isEmpty else {
            throw ToolValidationError.invalidArgument("ingredientsUsed", "At least one ingredient is required")
        }
        
        // Validate date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime]
        if formatter.date(from: dateCooked) == nil {
            // Try date-only format
            formatter.formatOptions = [.withFullDate]
            guard formatter.date(from: dateCooked) != nil else {
                throw ToolValidationError.invalidArgument("dateCooked", "Date must be in ISO format")
            }
        }
        
        for ingredient in ingredientsUsed {
            guard ingredient.quantity > 0 else {
                throw ToolValidationError.invalidArgument("ingredientsUsed", "All ingredient quantities must be greater than zero")
            }
        }
    }
}

// MARK: - Tool Validation Error

enum ToolValidationError: LocalizedError {
    case invalidArgument(String, String)
    case itemNotFound(String)
    case insufficientInventory(String, available: Double, requested: Double)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidArgument(let arg, let reason):
            return "Invalid argument '\(arg)': \(reason)"
        case .itemNotFound(let id):
            return "Item not found: \(id)"
        case .insufficientInventory(let item, let available, let requested):
            return "Insufficient inventory for \(item): available \(available), requested \(requested)"
        case .executionFailed(let reason):
            return "Execution failed: \(reason)"
        }
    }
}

// MARK: - Tool Executor Protocol

protocol ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable]
}

struct ToolExecutionContext {
    let modelContext: ModelContext
    let inventoryService: InventoryService
    let dishLogService: DishLogService
    let plannerService: PlannerService
    let groceryService: GroceryService
    let userProfile: UserProfile?
}

// MARK: - Tool Registry

final class ToolRegistry {
    private let executors: [ToolName: ToolExecutor]
    
    init(executors: [ToolName: ToolExecutor]) {
        self.executors = executors
    }
    
    func validateToolCall(tool: String, args: [String: AnyCodable]) throws {
        guard let toolName = ToolName(rawValue: tool) else {
            throw ToolValidationError.invalidArgument("tool", "Unknown tool: \(tool)")
        }
        
        // Decode and validate args based on tool
        switch toolName {
        case .addInventoryItem:
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
            _ = try decoder.decode(AddInventoryItemArgs.self, from: data)
        case .updateInventoryQuantity:
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
            let toolArgs = try decoder.decode(UpdateInventoryQuantityArgs.self, from: data)
            try toolArgs.validate()
        case .createPlannedMeal:
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
            let toolArgs = try decoder.decode(CreatePlannedMealArgs.self, from: data)
            try toolArgs.validate()
        case .generateGroceryList:
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
            let toolArgs = try decoder.decode(GenerateGroceryListArgs.self, from: data)
            try toolArgs.validate()
        case .logCookedDish:
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
            let toolArgs = try decoder.decode(LogCookedDishArgs.self, from: data)
            try toolArgs.validate()
        }
    }
    
    func executeTool(tool: String, args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        guard let toolName = ToolName(rawValue: tool) else {
            throw ToolValidationError.invalidArgument("tool", "Unknown tool: \(tool)")
        }
        
        guard let executor = executors[toolName] else {
            throw ToolValidationError.executionFailed("No executor registered for tool: \(tool)")
        }
        
        return try await executor.execute(args: args, context: context)
    }
}

