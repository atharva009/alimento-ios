//
//  InventoryItem.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class InventoryItem {
    var name: String
    var category: String // e.g., "Produce", "Dairy", "Grains", "Meat", "Spices"
    var quantity: Double
    var unit: String // e.g., "kg", "g", "L", "mL", "pieces", "cans"
    var location: String // "pantry", "fridge", "freezer"
    var purchaseDate: Date
    var expiryDate: Date? // Optional expiry date
    var lowStockThreshold: Double // Alert when quantity falls below this
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \DishIngredient.inventoryItem)
    var dishIngredients: [DishIngredient]?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        category: String,
        quantity: Double,
        unit: String,
        location: String,
        purchaseDate: Date = Date(),
        expiryDate: Date? = nil,
        lowStockThreshold: Double = 0.0
    ) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.location = location
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.lowStockThreshold = lowStockThreshold
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed properties
    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }
    
    var isExpiringSoon: Bool {
        guard let expiryDate = expiryDate else { return false }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return daysUntilExpiry >= 0 && daysUntilExpiry <= 3
    }
}

