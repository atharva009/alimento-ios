//
//  DishIngredient.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class DishIngredient {
    var amountUsed: Double
    var unit: String
    
    // Relationships
    var dish: Dish?
    var inventoryItem: InventoryItem?
    
    // Optional: if ingredient wasn't from inventory, store name
    var ingredientName: String? // For ingredients not linked to inventory
    
    init(
        amountUsed: Double,
        unit: String,
        dish: Dish? = nil,
        inventoryItem: InventoryItem? = nil,
        ingredientName: String? = nil
    ) {
        self.amountUsed = amountUsed
        self.unit = unit
        self.dish = dish
        self.inventoryItem = inventoryItem
        self.ingredientName = ingredientName
    }
    
    // Computed property for display
    var displayName: String {
        inventoryItem?.name ?? ingredientName ?? "Unknown Ingredient"
    }
}

