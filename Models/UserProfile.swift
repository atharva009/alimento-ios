//
//  UserProfile.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    // Dietary preferences
    var dietaryPreference: String // "none", "vegetarian", "vegan", "halal", "keto", etc.
    var allergies: [String] // Array of allergy tags
    var allergiesFreeText: String // Additional allergy notes
    var dislikedIngredients: [String] // Array of disliked ingredient names
    
    // Cuisine preferences
    var cuisinePreferences: [String] // e.g., ["Italian", "Mexican", "Asian"]
    
    // Cooking preferences
    var preferredCookingTimeMinutes: Int // 15, 30, 45, 60
    
    // Health goals
    var calorieTarget: Int? // Optional daily calorie target
    var proteinTargetG: Double? // Optional protein target in grams
    var carbsTargetG: Double? // Optional carbs target in grams
    var fatTargetG: Double? // Optional fat target in grams
    var useBalancedMacros: Bool // If true, ignore specific macro targets
    
    // Budget
    var weeklyBudget: Double? // Optional weekly budget in currency
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        dietaryPreference: String = "none",
        allergies: [String] = [],
        allergiesFreeText: String = "",
        dislikedIngredients: [String] = [],
        cuisinePreferences: [String] = [],
        preferredCookingTimeMinutes: Int = 30,
        calorieTarget: Int? = nil,
        proteinTargetG: Double? = nil,
        carbsTargetG: Double? = nil,
        fatTargetG: Double? = nil,
        useBalancedMacros: Bool = true,
        weeklyBudget: Double? = nil
    ) {
        self.dietaryPreference = dietaryPreference
        self.allergies = allergies
        self.allergiesFreeText = allergiesFreeText
        self.dislikedIngredients = dislikedIngredients
        self.cuisinePreferences = cuisinePreferences
        self.preferredCookingTimeMinutes = preferredCookingTimeMinutes
        self.calorieTarget = calorieTarget
        self.proteinTargetG = proteinTargetG
        self.carbsTargetG = carbsTargetG
        self.fatTargetG = fatTargetG
        self.useBalancedMacros = useBalancedMacros
        self.weeklyBudget = weeklyBudget
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

