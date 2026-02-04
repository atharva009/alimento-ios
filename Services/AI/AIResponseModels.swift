//
//  AIResponseModels.swift
//  Alimento
//
//  Created on Phase 7
//  Internal models for JSON decoding from Gemini API
//

import Foundation

// MARK: - Meal Suggestions Response

struct MealSuggestionResponse: Decodable {
    let suggestions: [MealSuggestionJSON]
}

struct MealSuggestionJSON: Decodable {
    let title: String
    let description: String
    let cookTimeMinutes: Int
    let requiredIngredients: [IngredientRequirementJSON]
    let missingIngredients: [IngredientRequirementJSON]
    let steps: [String]
    let estimatedMacros: MacroEstimateJSON
    let disclaimer: String
}

struct IngredientRequirementJSON: Decodable {
    let name: String
    let quantity: Double
    let unit: String
}

struct MacroEstimateJSON: Decodable {
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

// MARK: - Weekly Meal Plan Response

struct WeeklyMealPlanResponse: Decodable {
    let weekStart: String
    let days: [DayMealPlanJSON]
    let dailyMacroEstimates: [DailyMacroEstimateJSON]
    let prepPlan: [String]
    let disclaimer: String
}

struct DayMealPlanJSON: Decodable {
    let date: String
    let meals: MealPlanJSON
}

struct MealPlanJSON: Decodable {
    let breakfast: MealPlanItemJSON?
    let lunch: MealPlanItemJSON?
    let dinner: MealPlanItemJSON?
    let snack: MealPlanItemJSON?
}

struct MealPlanItemJSON: Decodable {
    let title: String
    let description: String?
    let cookTimeMinutes: Int?
    let ingredients: [IngredientRequirementJSON]?
}

struct DailyMacroEstimateJSON: Decodable {
    let date: String
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

// MARK: - Grocery List Response

struct GroceryListSuggestionResponse: Decodable {
    let items: [GroceryItemSuggestionJSON]
    let disclaimer: String
}

struct GroceryItemSuggestionJSON: Decodable {
    let name: String
    let quantity: Double
    let unit: String
    let reason: String
    let priority: Int
}

