//
//  Dish.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class Dish {
    var name: String
    var servings: Int
    var dateCooked: Date
    var steps: String? // Optional cooking steps/notes
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var ingredients: [DishIngredient]?
    
    @Relationship(deleteRule: .nullify, inverse: \PlannedMeal.dish)
    var plannedMeals: [PlannedMeal]?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        servings: Int,
        dateCooked: Date = Date(),
        steps: String? = nil
    ) {
        self.name = name
        self.servings = servings
        self.dateCooked = dateCooked
        self.steps = steps
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

