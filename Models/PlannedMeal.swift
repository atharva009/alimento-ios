//
//  PlannedMeal.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class PlannedMeal {
    var date: Date
    var mealType: String // "breakfast", "lunch", "dinner", "snack"
    var title: String
    
    // Relationships
    var dish: Dish? // Optional link to a logged dish
    
    // Optional: ingredients array stored as JSON string or separate model
    // For Phase 1, we'll use a simple array of ingredient names
    var ingredientNames: [String] // Simple array for ingredients not linked to Dish
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        date: Date,
        mealType: String,
        title: String,
        dish: Dish? = nil,
        ingredientNames: [String] = []
    ) {
        self.date = date
        self.mealType = mealType
        self.title = title
        self.dish = dish
        self.ingredientNames = ingredientNames
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

