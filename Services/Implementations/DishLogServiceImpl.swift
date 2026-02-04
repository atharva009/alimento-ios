//
//  DishLogServiceImpl.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData

@MainActor
final class DishLogServiceImpl: DishLogService {
    private let modelContext: ModelContext
    private let inventoryService: InventoryService
    
    init(modelContext: ModelContext, inventoryService: InventoryService) {
        self.modelContext = modelContext
        self.inventoryService = inventoryService
    }
    
    func logDish(
        name: String,
        servings: Int,
        dateCooked: Date,
        steps: String?,
        ingredients: [(inventoryItem: InventoryItem?, name: String?, amount: Double, unit: String)]
    ) async throws -> Dish {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DomainError.invalidDishData(message: "Dish name cannot be empty")
        }
        
        guard servings > 0 else {
            throw DomainError.invalidDishData(message: "Servings must be greater than zero")
        }
        
        guard !ingredients.isEmpty else {
            throw DomainError.invalidDishData(message: "At least one ingredient is required")
        }
        
        // Create dish
        let dish = Dish(
            name: name,
            servings: servings,
            dateCooked: dateCooked,
            steps: steps
        )
        
        modelContext.insert(dish)
        
        // Create dish ingredients and decrement inventory atomically
        var ingredientsToDecrement: [(InventoryItem, Double)] = []
        
        for ingredient in ingredients {
            let dishIngredient = DishIngredient(
                amountUsed: ingredient.amount,
                unit: ingredient.unit,
                dish: dish,
                inventoryItem: ingredient.inventoryItem,
                ingredientName: ingredient.name
            )
            
            modelContext.insert(dishIngredient)
            
            // Track inventory items to decrement
            if let inventoryItem = ingredient.inventoryItem {
                ingredientsToDecrement.append((inventoryItem, ingredient.amount))
            }
        }
        
        // Decrement inventory (all or nothing)
        do {
            for (item, amount) in ingredientsToDecrement {
                try await inventoryService.consumeItem(item, amount: amount, unit: item.unit)
            }
            
            try modelContext.save()
            return dish
        } catch {
            // Rollback: delete the dish (ingredients cascade delete)
            modelContext.delete(dish)
            try? modelContext.save()
            throw error
        }
    }
    
    func updateDish(_ dish: Dish) async throws {
        dish.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to update dish: \(error.localizedDescription)")
        }
    }
    
    func deleteDish(_ dish: Dish) async throws {
        // Check if dish is referenced by planned meals
        let mealDescriptor = FetchDescriptor<PlannedMeal>()
        let allMeals = (try? modelContext.fetch(mealDescriptor)) ?? []
        let referencedMeals = allMeals.filter { meal in
            meal.dish?.persistentModelID == dish.persistentModelID
        }
        
        if !referencedMeals.isEmpty {
            // Unlink the dish from planned meals instead of blocking deletion
            for meal in referencedMeals {
                meal.dish = nil
            }
        }
        
        modelContext.delete(dish)
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to delete dish: \(error.localizedDescription)")
        }
    }
    
    func fetchAllDishes() async throws -> [Dish] {
        let descriptor = FetchDescriptor<Dish>(
            sortBy: [SortDescriptor(\.dateCooked, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch dishes: \(error.localizedDescription)")
        }
    }
    
    func fetchDishes(in dateRange: ClosedRange<Date>) async throws -> [Dish] {
        let descriptor = FetchDescriptor<Dish>(
            predicate: #Predicate { dish in
                dish.dateCooked >= dateRange.lowerBound && dish.dateCooked <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.dateCooked, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch dishes in date range: \(error.localizedDescription)")
        }
    }
    
    func fetchDish(by id: PersistentIdentifier) async throws -> Dish? {
        let descriptor = FetchDescriptor<Dish>(
            predicate: #Predicate { $0.persistentModelID == id }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch dish: \(error.localizedDescription)")
        }
    }
}

