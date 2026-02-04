//
//  PromptBuilder.swift
//  Alimento
//
//  Created on Phase 7
//

import Foundation

final class PromptBuilder {
    static let systemInstruction = """
    You are a helpful meal planning assistant. You provide meal suggestions, weekly meal plans, and grocery list recommendations.
    
    Important guidelines:
    - Return ONLY valid JSON that matches the requested schema
    - No markdown formatting, no code fences, no backticks
    - No commentary or explanations outside the JSON
    - All nutritional information is an estimate only
    - Do not provide medical advice
    - Focus on general wellness and balanced nutrition
    - Be creative but practical with meal suggestions
    """
    
    static func buildMealSuggestionPrompt(
        inventory: [InventorySummary],
        preferences: UserPreferences
    ) -> String {
        let inventoryText = inventory.map { item in
            var text = "\(item.name): \(item.quantity) \(item.unit) (\(item.location))"
            if let expiry = item.expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                text += ", expires: \(formatter.string(from: expiry))"
            }
            return text
        }.joined(separator: "\n")
        
        var preferencesText = ""
        if !preferences.dietaryPreference.isEmpty {
            preferencesText += "Dietary preference: \(preferences.dietaryPreference)\n"
        }
        if !preferences.allergies.isEmpty {
            preferencesText += "Allergies: \(preferences.allergies.joined(separator: ", "))\n"
        }
        if !preferences.dislikedIngredients.isEmpty {
            preferencesText += "Disliked ingredients: \(preferences.dislikedIngredients.joined(separator: ", "))\n"
        }
        if !preferences.preferredCuisines.isEmpty {
            preferencesText += "Preferred cuisines: \(preferences.preferredCuisines.joined(separator: ", "))\n"
        }
        if preferences.maxCookTimeMinutes > 0 {
            preferencesText += "Max cook time: \(preferences.maxCookTimeMinutes) minutes\n"
        }
        
        return """
        Suggest 3-5 meal ideas based on the following inventory and preferences.
        
        Current Inventory:
        \(inventoryText)
        
        User Preferences:
        \(preferencesText.isEmpty ? "None specified" : preferencesText)
        
        For each meal suggestion, provide:
        - A creative title
        - A brief description
        - Estimated cook time in minutes
        - Required ingredients (name, quantity, unit)
        - Missing ingredients that need to be purchased (name, quantity, unit)
        - Step-by-step cooking instructions
        - Estimated nutritional information (calories, protein, carbs, fat in grams)
        - A disclaimer that nutritional information is an estimate only
        
        Prioritize meals that use ingredients already in inventory. Be creative with combinations.
        """
    }
    
    static func buildWeeklyMealPlanPrompt(
        weekStart: Date,
        preferences: UserPreferences,
        mealsPerDay: Int = 3
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekStartString = formatter.string(from: weekStart)
        
        var preferencesText = ""
        if !preferences.dietaryPreference.isEmpty {
            preferencesText += "Dietary preference: \(preferences.dietaryPreference)\n"
        }
        if !preferences.allergies.isEmpty {
            preferencesText += "Allergies: \(preferences.allergies.joined(separator: ", "))\n"
        }
        if !preferences.dislikedIngredients.isEmpty {
            preferencesText += "Disliked ingredients: \(preferences.dislikedIngredients.joined(separator: ", "))\n"
        }
        if !preferences.preferredCuisines.isEmpty {
            preferencesText += "Preferred cuisines: \(preferences.preferredCuisines.joined(separator: ", "))\n"
        }
        
        var goalsText = ""
        if preferences.targetCaloriesPerDay > 0 {
            goalsText += "Target calories per day: \(preferences.targetCaloriesPerDay)\n"
        }
        if preferences.targetProteinG > 0 {
            goalsText += "Target protein: \(preferences.targetProteinG)g\n"
        }
        if preferences.targetCarbsG > 0 {
            goalsText += "Target carbs: \(preferences.targetCarbsG)g\n"
        }
        if preferences.targetFatG > 0 {
            goalsText += "Target fat: \(preferences.targetFatG)g\n"
        }
        if goalsText.isEmpty {
            goalsText = "Balanced nutrition (no specific macro targets)\n"
        }
        
        return """
        Generate a weekly meal plan starting from \(weekStartString).
        
        User Preferences:
        \(preferencesText.isEmpty ? "None specified" : preferencesText)
        
        Nutrition Goals:
        \(goalsText)
        
        Meals per day: \(mealsPerDay)
        
        For each day of the week, provide:
        - Breakfast, lunch, dinner, and optional snack suggestions
        - Each meal should include: title, optional description, optional cook time, optional ingredients list
        - Daily macro estimates (calories, protein, carbs, fat in grams)
        - A weekly meal prep plan with tips
        - A disclaimer that all nutritional information is an estimate only
        
        Ensure variety throughout the week and balance nutritional goals.
        """
    }
    
    static func buildGroceryListPrompt(
        plannedMeals: [PlannedMealSummary],
        inventory: [InventorySummary],
        lowStockItems: [InventorySummary]
    ) -> String {
        let mealsText = plannedMeals.map { meal in
            "\(meal.title) on \(meal.date) - \(meal.mealType)"
        }.joined(separator: "\n")
        
        let inventoryText = inventory.map { item in
            "\(item.name): \(item.quantity) \(item.unit) (\(item.location))"
        }.joined(separator: "\n")
        
        let lowStockText = lowStockItems.map { item in
            "\(item.name): \(item.quantity) \(item.unit) (low stock, threshold: \(item.lowStockThreshold))"
        }.joined(separator: "\n")
        
        return """
        Generate a grocery list based on the following:
        
        Planned Meals:
        \(mealsText.isEmpty ? "None" : mealsText)
        
        Current Inventory:
        \(inventoryText.isEmpty ? "Empty" : inventoryText)
        
        Low Stock Items:
        \(lowStockText.isEmpty ? "None" : lowStockText)
        
        For each item, provide:
        - Name
        - Quantity needed
        - Unit
        - Reason (missing, low_stock, or staple)
        - Priority (1=high, 2=medium, 3=low)
        
        Only include items that are actually needed. Deduplicate items with the same name and unit.
        """
    }
}

// MARK: - Supporting Types

struct InventorySummary {
    let name: String
    let quantity: Double
    let unit: String
    let location: String
    let expiryDate: Date?
    let lowStockThreshold: Double
}

struct UserPreferences {
    let dietaryPreference: String
    let allergies: [String]
    let dislikedIngredients: [String]
    let preferredCuisines: [String]
    let maxCookTimeMinutes: Int
    let targetCaloriesPerDay: Int
    let targetProteinG: Int
    let targetCarbsG: Int
    let targetFatG: Int
}

struct PlannedMealSummary {
    let title: String
    let date: String
    let mealType: String
}

