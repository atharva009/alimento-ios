//
//  GroceryViewModel.swift
//  Alimento
//
//  Created on Phase 6
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class GroceryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var activeList: GroceryList?
    @Published var groceryItems: [GroceryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Private Properties
    
    private let groceryService: GroceryService
    private let plannerService: PlannerService
    private let inventoryService: InventoryService
    
    // MARK: - Computed Properties
    
    var toBuyItems: [GroceryItem] {
        groceryItems.filter { !$0.isPurchased }
    }
    
    var purchasedItems: [GroceryItem] {
        groceryItems.filter { $0.isPurchased }
    }
    
    // MARK: - Initialization
    
    init(groceryService: GroceryService, plannerService: PlannerService, inventoryService: InventoryService) {
        self.groceryService = groceryService
        self.plannerService = plannerService
        self.inventoryService = inventoryService
    }
    
    // MARK: - Public Methods
    
    func loadActiveList() async {
        isLoading = true
        errorMessage = nil
        
        do {
            activeList = try await groceryService.fetchActiveGroceryList()
            if let list = activeList {
                // Sort once when loading, not in computed property
                groceryItems = list.items?.sorted(by: { $0.createdAt < $1.createdAt }) ?? []
            } else {
                groceryItems = []
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refreshList() async {
        await loadActiveList()
    }
    
    func addItem(
        name: String,
        quantity: Double?,
        unit: String?,
        reason: String?,
        priority: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Ensure we have an active list
            if activeList == nil {
                activeList = try await groceryService.createGroceryList(daysAhead: 7)
            }
            
            guard let list = activeList else {
                throw DomainError.groceryListNotFound
            }
            
            _ = try await groceryService.addItemToList(
                list,
                name: name,
                quantity: quantity ?? 1.0,
                unit: unit ?? "pieces",
                reason: reason ?? "manual",
                priority: priorityToInt(priority ?? "medium")
            )
            
            await loadActiveList()
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func updateItem(
        _ item: GroceryItem,
        name: String,
        quantity: Double?,
        unit: String?,
        reason: String?,
        priority: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        item.name = name
        item.quantity = quantity ?? 1.0
        item.unit = unit ?? "pieces"
        item.reason = reason ?? item.reason
        item.priority = priorityToInt(priority)
        item.updatedAt = Date()
        
        do {
            try await groceryService.updateItem(item)
            await loadActiveList()
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func deleteItem(_ item: GroceryItem) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await groceryService.deleteItem(item)
            await loadActiveList()
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func togglePurchased(_ item: GroceryItem) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let newPurchasedState = !item.isPurchased
        
        do {
            try await groceryService.markItemPurchased(item, isPurchased: newPurchasedState)
            await loadActiveList()
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func generateList(
        daysAhead: Int,
        includePlannedMeals: Bool,
        includeLowStock: Bool
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create or update list first
            if activeList == nil {
                activeList = try await groceryService.createGroceryList(daysAhead: daysAhead)
            }
            
            guard let list = activeList else {
                throw DomainError.groceryListNotFound
            }
            
            // Collect items to add (as structs, not SwiftData models)
            struct ItemToAdd {
                let name: String
                var quantity: Double
                let unit: String
                var reason: String
                var priority: Int
            }
            
            var itemsToAdd: [String: ItemToAdd] = [:]
            
            // Generate from planned meals
            if includePlannedMeals {
                let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()
                let dateRange = Date()...endDate
                
                let plannedMeals = try await plannerService.fetchPlannedMeals(in: dateRange)
                
                for plannedMeal in plannedMeals {
                    // Only process meals linked to dishes
                    guard let dish = plannedMeal.dish, let ingredients = dish.ingredients else {
                        continue
                    }
                    
                    for ingredient in ingredients {
                        // Get ingredient name
                        let ingredientName = ingredient.displayName
                        
                        // Check inventory
                        let inventoryItems = try await inventoryService.fetchAllItems()
                        let matchingInventory = inventoryItems.first { item in
                            normalizeName(item.name) == normalizeName(ingredientName) &&
                            item.unit.lowercased() == ingredient.unit.lowercased()
                        }
                        
                        // Calculate needed quantity
                        let neededQuantity = ingredient.amountUsed
                        let availableQuantity = matchingInventory?.quantity ?? 0
                        
                        if neededQuantity > availableQuantity {
                            let missingQuantity = neededQuantity - availableQuantity
                            let key = dedupeKey(name: ingredientName, unit: ingredient.unit)
                            
                            if let existing = itemsToAdd[key] {
                                itemsToAdd[key] = ItemToAdd(
                                    name: existing.name,
                                    quantity: existing.quantity + missingQuantity,
                                    unit: existing.unit,
                                    reason: existing.reason,
                                    priority: existing.priority
                                )
                            } else {
                                itemsToAdd[key] = ItemToAdd(
                                    name: ingredientName,
                                    quantity: missingQuantity,
                                    unit: ingredient.unit,
                                    reason: "missing",
                                    priority: 1
                                )
                            }
                        }
                    }
                }
            }
            
            // Generate from low stock
            if includeLowStock {
                let inventoryItems = try await inventoryService.fetchAllItems()
                let lowStockItems = inventoryItems.filter { $0.isLowStock }
                
                for item in lowStockItems {
                    // Calculate restock quantity: threshold - current, minimum 1
                    let restockQuantity = max(1.0, item.lowStockThreshold - item.quantity)
                    let key = dedupeKey(name: item.name, unit: item.unit)
                    
                    if let existing = itemsToAdd[key] {
                        // Merge with existing
                        itemsToAdd[key] = ItemToAdd(
                            name: existing.name,
                            quantity: existing.quantity + restockQuantity,
                            unit: existing.unit,
                            reason: existing.reason == "missing" ? "missing" : "low_stock",
                            priority: existing.priority
                        )
                    } else {
                        itemsToAdd[key] = ItemToAdd(
                            name: item.name,
                            quantity: restockQuantity,
                            unit: item.unit,
                            reason: "low_stock",
                            priority: 2
                        )
                    }
                }
            }
            
            // Add all items to list
            for item in itemsToAdd.values {
                _ = try await groceryService.addItemToList(
                    list,
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit,
                    reason: item.reason,
                    priority: item.priority
                )
            }
            
            await loadActiveList()
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    func addPurchasedToInventory(_ item: GroceryItem, location: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        guard item.quantity > 0 else {
            errorMessage = "Item must have a quantity to add to inventory"
            showingError = true
            isLoading = false
            return false
        }
        
        guard !item.unit.isEmpty else {
            errorMessage = "Item must have a unit to add to inventory"
            showingError = true
            isLoading = false
            return false
        }
        
        do {
            // Use service method which handles the logic
            _ = try await groceryService.addPurchasedItemToInventory(item)
            
            isLoading = false
            return true
        } catch {
            handleError(error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Dedupe/Merge Logic
    
    private func dedupeKey(name: String, unit: String) -> String {
        let normalizedName = normalizeName(name)
        let normalizedUnit = unit.lowercased()
        return "\(normalizedName)|\(normalizedUnit)"
    }
    
    private func normalizeName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
    
    // MARK: - Validation
    
    func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Item name cannot be empty"
        }
        return nil
    }
    
    func validateQuantity(_ quantity: Double?) -> String? {
        if let qty = quantity, qty <= 0 {
            return "Quantity must be greater than zero"
        }
        return nil
    }
    
    func priorityToInt(_ priority: String?) -> Int {
        switch priority?.lowercased() {
        case "high": return 1
        case "medium", "med": return 2
        case "low": return 3
        default: return 2
        }
    }
    
    func intToPriority(_ priority: Int) -> String {
        switch priority {
        case 1: return "high"
        case 2: return "medium"
        case 3: return "low"
        default: return "medium"
        }
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        if let domainError = error as? DomainError {
            errorMessage = domainError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
}
