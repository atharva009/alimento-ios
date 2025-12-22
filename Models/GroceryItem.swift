//
//  GroceryItem.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class GroceryItem {
    var name: String
    var quantity: Double
    var unit: String
    var reason: String // "missing", "low_stock", "staple"
    var priority: Int // 1 = high, 2 = medium, 3 = low
    var isPurchased: Bool
    
    // Relationships
    var groceryList: GroceryList?
    
    // Optional link to inventory item (if adding to existing item)
    var inventoryItem: InventoryItem?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        quantity: Double,
        unit: String,
        reason: String,
        priority: Int = 2,
        isPurchased: Bool = false,
        groceryList: GroceryList? = nil,
        inventoryItem: InventoryItem? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.reason = reason
        self.priority = priority
        self.isPurchased = isPurchased
        self.groceryList = groceryList
        self.inventoryItem = inventoryItem
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

