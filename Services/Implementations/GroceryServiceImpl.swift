//
//  GroceryServiceImpl.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData

@MainActor
final class GroceryServiceImpl: GroceryService {
    private let modelContext: ModelContext
    private let inventoryService: InventoryService
    private let plannerService: PlannerService
    
    init(modelContext: ModelContext, inventoryService: InventoryService, plannerService: PlannerService) {
        self.modelContext = modelContext
        self.inventoryService = inventoryService
        self.plannerService = plannerService
    }
    
    // MARK: - List Operations
    
    func generateGroceryList(daysAhead: Int) async throws -> GroceryList {
        guard daysAhead > 0 else {
            throw DomainError.validationFailed(message: "Days ahead must be greater than zero")
        }
        
        // Get planned meals for the date range
        let startDate = Calendar.current.startOfDay(for: Date())
        guard let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: startDate) else {
            throw DomainError.invalidDate
        }
        
        let dateRange = startDate...endDate
        let plannedMeals = try await plannerService.fetchPlannedMeals(in: dateRange)
        
        // Get low stock items
        let lowStockItems = try await inventoryService.fetchLowStockItems()
        
        // Get current inventory for comparison
        let currentInventory = try await inventoryService.fetchAllItems()
        
        // Create grocery list
        let groceryList = GroceryList(
            generatedAt: Date(),
            daysAhead: daysAhead
        )
        
        modelContext.insert(groceryList)
        
        // Generate items from planned meals (missing ingredients)
        var groceryItems: [String: GroceryItem] = [:] // Key: "name:unit"
        
        for meal in plannedMeals {
            // If meal has a linked dish, get ingredients from dish
            if let dish = meal.dish, let dishIngredients = dish.ingredients {
                for dishIngredient in dishIngredients {
                    let ingredientName = dishIngredient.displayName
                    let requiredAmount = dishIngredient.amountUsed
                    let unit = dishIngredient.unit
                    
                    // Check if we have enough in inventory
                    if let inventoryItem = dishIngredient.inventoryItem {
                        let available = inventoryItem.quantity
                        if available < requiredAmount {
                            let needed = requiredAmount - available
                            addOrMergeGroceryItem(
                                to: &groceryItems,
                                name: ingredientName,
                                quantity: needed,
                                unit: unit,
                                reason: "missing",
                                priority: 1,
                                groceryList: groceryList
                            )
                        }
                    } else {
                        // Non-inventory ingredient - always add
                        addOrMergeGroceryItem(
                            to: &groceryItems,
                            name: ingredientName,
                            quantity: requiredAmount,
                            unit: unit,
                            reason: "missing",
                            priority: 1,
                            groceryList: groceryList
                        )
                    }
                }
            } else {
                // Meal has ingredient names but no dish link
                for ingredientName in meal.ingredientNames {
                    // Check if ingredient exists in inventory
                    let matchingInventory = currentInventory.first { $0.name.lowercased() == ingredientName.lowercased() }
                    
                    if let inventoryItem = matchingInventory {
                        // Check if low stock
                        if inventoryItem.isLowStock {
                            addOrMergeGroceryItem(
                                to: &groceryItems,
                                name: ingredientName,
                                quantity: inventoryItem.lowStockThreshold - inventoryItem.quantity + 1, // Restock to threshold + 1
                                unit: inventoryItem.unit,
                                reason: "low_stock",
                                priority: 2,
                                groceryList: groceryList
                            )
                        }
                    } else {
                        // Not in inventory - add as missing
                        addOrMergeGroceryItem(
                            to: &groceryItems,
                            name: ingredientName,
                            quantity: 1, // Default quantity
                            unit: "pieces", // Default unit
                            reason: "missing",
                            priority: 1,
                            groceryList: groceryList
                        )
                    }
                }
            }
        }
        
        // Add low stock items
        for item in lowStockItems {
            let key = "\(item.name):\(item.unit)"
            if groceryItems[key] == nil {
                // Not already added from planned meals
                let needed = item.lowStockThreshold - item.quantity + 1 // Restock to threshold + 1
                addOrMergeGroceryItem(
                    to: &groceryItems,
                    name: item.name,
                    quantity: needed,
                    unit: item.unit,
                    reason: "low_stock",
                    priority: 2,
                    groceryList: groceryList
                )
            }
        }
        
        // Insert all grocery items
        for item in groceryItems.values {
            modelContext.insert(item)
        }
        
        do {
            try modelContext.save()
            return groceryList
        } catch {
            throw DomainError.persistenceError(message: "Failed to generate grocery list: \(error.localizedDescription)")
        }
    }
    
    func createGroceryList(daysAhead: Int) async throws -> GroceryList {
        guard daysAhead > 0 else {
            throw DomainError.validationFailed(message: "Days ahead must be greater than zero")
        }
        
        let groceryList = GroceryList(
            generatedAt: Date(),
            daysAhead: daysAhead
        )
        
        modelContext.insert(groceryList)
        
        do {
            try modelContext.save()
            return groceryList
        } catch {
            throw DomainError.persistenceError(message: "Failed to create grocery list: \(error.localizedDescription)")
        }
    }
    
    func fetchActiveGroceryList() async throws -> GroceryList? {
        let descriptor = FetchDescriptor<GroceryList>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        
        do {
            let lists = try modelContext.fetch(descriptor)
            return lists.first
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch active grocery list: \(error.localizedDescription)")
        }
    }
    
    func fetchAllGroceryLists() async throws -> [GroceryList] {
        let descriptor = FetchDescriptor<GroceryList>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch grocery lists: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Item Operations
    
    func addItemToList(
        _ list: GroceryList,
        name: String,
        quantity: Double,
        unit: String,
        reason: String,
        priority: Int
    ) async throws -> GroceryItem {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DomainError.invalidGroceryItem(reason: "Item name cannot be empty")
        }
        
        guard quantity > 0 else {
            throw DomainError.invalidGroceryItem(reason: "Quantity must be greater than zero")
        }
        
        guard priority >= 1 && priority <= 3 else {
            throw DomainError.invalidGroceryItem(reason: "Priority must be between 1 and 3")
        }
        
        // Check for existing item with same name and unit
        let existingItems = list.items ?? []
        if let existingItem = existingItems.first(where: { $0.name.lowercased() == name.lowercased() && $0.unit.lowercased() == unit.lowercased() && !$0.isPurchased }) {
            // Merge quantities
            existingItem.quantity += quantity
            existingItem.updatedAt = Date()
            
            do {
                try modelContext.save()
                return existingItem
            } catch {
                throw DomainError.mergeFailed(reason: error.localizedDescription)
            }
        }
        
        // Create new item
        let item = GroceryItem(
            name: name,
            quantity: quantity,
            unit: unit,
            reason: reason,
            priority: priority,
            isPurchased: false,
            groceryList: list
        )
        
        modelContext.insert(item)
        
        do {
            try modelContext.save()
            return item
        } catch {
            throw DomainError.persistenceError(message: "Failed to add grocery item: \(error.localizedDescription)")
        }
    }
    
    func updateItem(_ item: GroceryItem) async throws {
        guard !item.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DomainError.invalidGroceryItem(reason: "Item name cannot be empty")
        }
        
        guard item.quantity > 0 else {
            throw DomainError.invalidGroceryItem(reason: "Quantity must be greater than zero")
        }
        
        guard item.priority >= 1 && item.priority <= 3 else {
            throw DomainError.invalidGroceryItem(reason: "Priority must be between 1 and 3")
        }
        
        item.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to update grocery item: \(error.localizedDescription)")
        }
    }
    
    func deleteItem(_ item: GroceryItem) async throws {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to delete grocery item: \(error.localizedDescription)")
        }
    }
    
    func markItemPurchased(_ item: GroceryItem, isPurchased: Bool) async throws {
        item.isPurchased = isPurchased
        item.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to mark item as purchased: \(error.localizedDescription)")
        }
    }
    
    func addPurchasedItemToInventory(_ item: GroceryItem) async throws -> InventoryItem {
        guard item.isPurchased else {
            throw DomainError.validationFailed(message: "Item must be marked as purchased before adding to inventory")
        }
        
        // Check if item already exists in inventory
        let allInventory = try await inventoryService.fetchAllItems()
        if let existingItem = allInventory.first(where: { $0.name.lowercased() == item.name.lowercased() && $0.unit.lowercased() == item.unit.lowercased() }) {
            // Increment existing item
            try await inventoryService.updateQuantity(existingItem, delta: item.quantity)
            return existingItem
        } else {
            // Create new inventory item
            // Default location to pantry, category to "Other"
            let newItem = try await inventoryService.createItem(
                name: item.name,
                category: "Other",
                quantity: item.quantity,
                unit: item.unit,
                location: "pantry",
                purchaseDate: Date(),
                expiryDate: nil,
                lowStockThreshold: 0.0
            )
            
            // Link grocery item to inventory item
            item.inventoryItem = newItem
            
            do {
                try modelContext.save()
                return newItem
            } catch {
                throw DomainError.persistenceError(message: "Failed to link grocery item to inventory: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addOrMergeGroceryItem(
        to items: inout [String: GroceryItem],
        name: String,
        quantity: Double,
        unit: String,
        reason: String,
        priority: Int,
        groceryList: GroceryList
    ) {
        let key = "\(name.lowercased()):\(unit.lowercased())"
        
        if let existing = items[key] {
            // Merge quantities
            existing.quantity += quantity
            // Keep higher priority (lower number = higher priority)
            if priority < existing.priority {
                existing.priority = priority
            }
            // Update reason if needed (missing > low_stock > staple)
            if reason == "missing" || (reason == "low_stock" && existing.reason != "missing") {
                existing.reason = reason
            }
        } else {
            // Create new item
            let item = GroceryItem(
                name: name,
                quantity: quantity,
                unit: unit,
                reason: reason,
                priority: priority,
                isPurchased: false,
                groceryList: groceryList
            )
            items[key] = item
        }
    }
}

