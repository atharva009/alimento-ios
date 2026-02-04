//
//  SeedDataService.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData

@MainActor
final class SeedDataService {
    private let modelContext: ModelContext
    private let inventoryService: InventoryService
    private let dishLogService: DishLogService
    private let plannerService: PlannerService
    
    init(
        modelContext: ModelContext,
        inventoryService: InventoryService,
        dishLogService: DishLogService,
        plannerService: PlannerService
    ) {
        self.modelContext = modelContext
        self.inventoryService = inventoryService
        self.dishLogService = dishLogService
        self.plannerService = plannerService
    }
    
    func seedIfNeeded() async throws {
        // Check if data already exists
        let existingItems = try await inventoryService.fetchAllItems()
        if !existingItems.isEmpty {
            return // Already seeded
        }
        
        // Seed inventory items
        let inventoryItems = [
            ("Tomatoes", "Produce", 2.0, "kg", "fridge", Date().addingTimeInterval(86400 * 3)),
            ("Milk", "Dairy", 2.0, "L", "fridge", Date().addingTimeInterval(86400 * 5)),
            ("Chicken Breast", "Meat", 500.0, "g", "fridge", Date().addingTimeInterval(86400 * 2)),
            ("Rice", "Grains", 1.0, "kg", "pantry", nil),
            ("Pasta", "Grains", 500.0, "g", "pantry", nil),
            ("Olive Oil", "Spices", 500.0, "ml", "pantry", nil),
            ("Onions", "Produce", 1.0, "kg", "pantry", Date().addingTimeInterval(86400 * 7)),
            ("Garlic", "Produce", 100.0, "g", "pantry", Date().addingTimeInterval(86400 * 14)),
            ("Bread", "Grains", 1.0, "loaf", "pantry", Date().addingTimeInterval(86400 * 2)),
            ("Eggs", "Dairy", 12.0, "pieces", "fridge", Date().addingTimeInterval(86400 * 7))
        ]
        
        for (name, category, quantity, unit, location, expiryDate) in inventoryItems {
            _ = try await inventoryService.createItem(
                name: name,
                category: category,
                quantity: quantity,
                unit: unit,
                location: location,
                purchaseDate: Date(),
                expiryDate: expiryDate,
                lowStockThreshold: quantity * 0.3
            )
        }
        
        // Seed a sample dish
        let tomatoes = try await inventoryService.fetchAllItems().first { $0.name == "Tomatoes" }!
        let chicken = try await inventoryService.fetchAllItems().first { $0.name == "Chicken Breast" }!
        let rice = try await inventoryService.fetchAllItems().first { $0.name == "Rice" }!
        
        _ = try await dishLogService.logDish(
            name: "Chicken and Rice",
            servings: 4,
            dateCooked: Date(),
            steps: "Cook chicken, prepare rice, combine and serve",
            ingredients: [
                (chicken, nil, 400.0, "g"),
                (rice, nil, 300.0, "g"),
                (tomatoes, nil, 500.0, "g")
            ]
        )
        
        // Seed some planned meals
        let dish = try await dishLogService.fetchAllDishes().first!
        
        _ = try await plannerService.createPlannedMeal(
            date: Date(),
            mealType: "dinner",
            title: "Chicken and Rice",
            dish: dish,
            ingredientNames: []
        )
        
        _ = try await plannerService.createPlannedMeal(
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            mealType: "breakfast",
            title: "Scrambled Eggs",
            dish: nil,
            ingredientNames: ["Eggs", "Bread"]
        )
    }
}

