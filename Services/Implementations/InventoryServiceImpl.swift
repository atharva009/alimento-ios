//
//  InventoryServiceImpl.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData

@MainActor
final class InventoryServiceImpl: InventoryService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createItem(
        name: String,
        category: String,
        quantity: Double,
        unit: String,
        location: String,
        purchaseDate: Date,
        expiryDate: Date?,
        lowStockThreshold: Double
    ) async throws -> InventoryItem {
        guard quantity >= 0 else {
            throw DomainError.negativeQuantity
        }
        
        guard ["pantry", "fridge", "freezer"].contains(location.lowercased()) else {
            throw DomainError.invalidLocation(location: location)
        }
        
        let item = InventoryItem(
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            location: location.lowercased(),
            purchaseDate: purchaseDate,
            expiryDate: expiryDate,
            lowStockThreshold: lowStockThreshold
        )
        
        modelContext.insert(item)
        
        do {
            try modelContext.save()
            return item
        } catch {
            throw DomainError.persistenceError(message: "Failed to create inventory item: \(error.localizedDescription)")
        }
    }
    
    func updateItem(_ item: InventoryItem) async throws {
        guard item.quantity >= 0 else {
            throw DomainError.negativeQuantity
        }
        
        item.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to update inventory item: \(error.localizedDescription)")
        }
    }
    
    func deleteItem(_ item: InventoryItem) async throws {
        // Check if item is referenced by dishes
        let dishDescriptor = FetchDescriptor<DishIngredient>()
        let allIngredients = (try? modelContext.fetch(dishDescriptor)) ?? []
        let referencedIngredients = allIngredients.filter { ingredient in
            ingredient.inventoryItem?.persistentModelID == item.persistentModelID
        }
        
        if !referencedIngredients.isEmpty {
            throw DomainError.validationFailed(
                message: "Cannot delete \(item.name) because it is referenced by \(referencedIngredients.count) logged dish(es). Please remove those references first."
            )
        }
        
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            // Check for relationship errors
            let nsError = error as NSError
            if nsError.domain == "NSCocoaErrorDomain" {
                if nsError.code == 133024 { // NSValidationRelationshipDeniedDeleteError
                    throw DomainError.validationFailed(
                        message: "Cannot delete \(item.name) because it is referenced by other items."
                    )
                }
            }
            throw DomainError.persistenceError(message: "Failed to delete inventory item: \(error.localizedDescription)")
        }
    }
    
    func fetchAllItems() async throws -> [InventoryItem] {
        let descriptor = FetchDescriptor<InventoryItem>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch inventory items: \(error.localizedDescription)")
        }
    }
    
    func fetchItems(by location: String) async throws -> [InventoryItem] {
        let normalizedLocation = location.lowercased()
        let descriptor = FetchDescriptor<InventoryItem>(
            predicate: #Predicate<InventoryItem> { item in
                item.location == normalizedLocation
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch inventory items by location: \(error.localizedDescription)")
        }
    }
    
    func fetchLowStockItems() async throws -> [InventoryItem] {
        let allItems = try await fetchAllItems()
        return allItems.filter { $0.isLowStock }
    }
    
    func fetchExpiringSoonItems(daysAhead: Int) async throws -> [InventoryItem] {
        let allItems = try await fetchAllItems()
        return allItems.filter { item in
            guard let expiry = item.expiryDate else { return false }
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
            return daysUntilExpiry >= 0 && daysUntilExpiry <= daysAhead
        }
    }
    
    func updateQuantity(_ item: InventoryItem, delta: Double) async throws {
        let newQuantity = item.quantity + delta
        
        guard newQuantity >= 0 else {
            throw DomainError.negativeQuantity
        }
        
        item.quantity = newQuantity
        item.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to update quantity: \(error.localizedDescription)")
        }
    }
    
    func consumeItem(_ item: InventoryItem, amount: Double, unit: String) async throws {
        guard item.unit.lowercased() == unit.lowercased() else {
            throw DomainError.unitMismatch(itemName: item.name, expected: item.unit, provided: unit)
        }
        
        guard item.quantity >= amount else {
            throw DomainError.insufficientInventory(
                itemName: item.name,
                available: item.quantity,
                requested: amount
            )
        }
        
        try await updateQuantity(item, delta: -amount)
    }
}

