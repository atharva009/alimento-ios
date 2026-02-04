//
//  ToolExecutors.swift
//  Alimento
//
//  Created on Phase 8
//

import Foundation
import SwiftData

// MARK: - Add Inventory Item Executor

struct AddInventoryItemExecutor: ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
        let toolArgs = try decoder.decode(AddInventoryItemArgs.self, from: data)
        
        try toolArgs.validate()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let expiryDate = toolArgs.expiryDate.flatMap { formatter.date(from: $0) }
        
        let item = try await context.inventoryService.createItem(
            name: toolArgs.name,
            category: toolArgs.category ?? "uncategorized",
            quantity: toolArgs.quantity,
            unit: toolArgs.unit,
            location: toolArgs.location,
            purchaseDate: Date(),
            expiryDate: expiryDate,
            lowStockThreshold: 0.0
        )
        
        return [
            "itemId": AnyCodable(item.persistentModelID.hashValue.description),
            "name": AnyCodable(item.name),
            "quantity": AnyCodable(item.quantity),
            "unit": AnyCodable(item.unit),
            "location": AnyCodable(item.location)
        ]
    }
}

// MARK: - Update Inventory Quantity Executor

struct UpdateInventoryQuantityExecutor: ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
        let toolArgs = try decoder.decode(UpdateInventoryQuantityArgs.self, from: data)
        
        try toolArgs.validate()
        
        // Find item by ID (using hash value for lookup)
        // Note: In production, you'd want a better ID system
        let allItems = try await context.inventoryService.fetchAllItems()
        guard let item = allItems.first(where: { $0.persistentModelID.hashValue.description == toolArgs.itemId }) else {
            throw ToolValidationError.itemNotFound(toolArgs.itemId)
        }
        
        // Validate resulting quantity won't be negative
        let oldQuantity = item.quantity
        let newQuantity = oldQuantity + toolArgs.delta
        guard newQuantity >= 0 else {
            throw ToolValidationError.insufficientInventory(
                item.name,
                available: oldQuantity,
                requested: abs(toolArgs.delta)
            )
        }
        
        // Update quantity
        try await context.inventoryService.updateQuantity(item, delta: toolArgs.delta)
        
        return [
            "itemId": AnyCodable(item.persistentModelID.hashValue.description),
            "name": AnyCodable(item.name),
            "oldQuantity": AnyCodable(oldQuantity),
            "newQuantity": AnyCodable(item.quantity),
            "unit": AnyCodable(item.unit)
        ]
    }
}

// MARK: - Create Planned Meal Executor

struct CreatePlannedMealExecutor: ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
        let toolArgs = try decoder.decode(CreatePlannedMealArgs.self, from: data)
        
        try toolArgs.validate()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: toolArgs.date) else {
            throw ToolValidationError.invalidArgument("date", "Invalid date format")
        }
        
        // Find dish if dishId provided
        var dish: Dish? = nil
        if let dishIdString = toolArgs.dishId {
            // Find dish by hash value
            let descriptor = FetchDescriptor<Dish>()
            let allDishes = try? context.modelContext.fetch(descriptor)
            dish = allDishes?.first(where: { $0.persistentModelID.hashValue.description == dishIdString })
        }
        
        let title = toolArgs.title ?? dish?.name ?? "Meal"
        
        let meal = try await context.plannerService.createPlannedMeal(
            date: date,
            mealType: toolArgs.mealType,
            title: title,
            dish: dish,
            ingredientNames: []
        )
        
        return [
            "mealId": AnyCodable(meal.persistentModelID.hashValue.description),
            "date": AnyCodable(toolArgs.date),
            "mealType": AnyCodable(meal.mealType),
            "title": AnyCodable(meal.title)
        ]
    }
}

// MARK: - Generate Grocery List Executor

struct GenerateGroceryListExecutor: ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
        let toolArgs = try decoder.decode(GenerateGroceryListArgs.self, from: data)
        
        try toolArgs.validate()
        
        let list = try await context.groceryService.generateGroceryList(
            daysAhead: toolArgs.daysAhead
        )
        
        let items = list.items ?? []
        let topItems = Array(items.prefix(5)).map { item in
            [
                "name": AnyCodable(item.name),
                "quantity": AnyCodable(item.quantity),
                "unit": AnyCodable(item.unit)
            ]
        }
        
        return [
            "listId": AnyCodable(list.persistentModelID.hashValue.description),
            "itemCount": AnyCodable(items.count),
            "topItems": AnyCodable(topItems)
        ]
    }
}

// MARK: - Log Cooked Dish Executor

struct LogCookedDishExecutor: ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: args.mapValues { $0.value })
        let toolArgs = try decoder.decode(LogCookedDishArgs.self, from: data)
        
        try toolArgs.validate()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime]
        var dateCooked = formatter.date(from: toolArgs.dateCooked)
        if dateCooked == nil {
            formatter.formatOptions = [.withFullDate]
            dateCooked = formatter.date(from: toolArgs.dateCooked)
        }
        
        guard let cookedDate = dateCooked else {
            throw ToolValidationError.invalidArgument("dateCooked", "Invalid date format")
        }
        
        // Convert ingredients
        var ingredients: [(inventoryItem: InventoryItem?, name: String?, amount: Double, unit: String)] = []
        let allItems = try await context.inventoryService.fetchAllItems()
        
        for ingredientUsage in toolArgs.ingredientsUsed {
            var inventoryItem: InventoryItem? = nil
            
            // Find item by hash value
            inventoryItem = allItems.first(where: { $0.persistentModelID.hashValue.description == ingredientUsage.inventoryItemId })
            
            // Validate quantity doesn't exceed available
            if let item = inventoryItem {
                guard item.quantity >= ingredientUsage.quantity else {
                    throw ToolValidationError.insufficientInventory(
                        item.name,
                        available: item.quantity,
                        requested: ingredientUsage.quantity
                    )
                }
            }
            
            ingredients.append((
                inventoryItem: inventoryItem,
                name: inventoryItem?.name,
                amount: ingredientUsage.quantity,
                unit: ingredientUsage.unit
            ))
        }
        
        let dish = try await context.dishLogService.logDish(
            name: toolArgs.name,
            servings: toolArgs.servings,
            dateCooked: cookedDate,
            steps: nil,
            ingredients: ingredients
        )
        
        return [
            "dishId": AnyCodable(dish.persistentModelID.hashValue.description),
            "name": AnyCodable(dish.name),
            "servings": AnyCodable(dish.servings),
            "dateCooked": AnyCodable(toolArgs.dateCooked)
        ]
    }
}

