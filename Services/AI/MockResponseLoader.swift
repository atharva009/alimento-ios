//
//  MockResponseLoader.swift
//  Alimento
//
//  Created on Phase 7
//

import Foundation

final class MockResponseLoader {
    func loadMealSuggestions() throws -> [MealSuggestion] {
        guard let url = Bundle.main.url(forResource: "meal_suggestions", withExtension: "json", subdirectory: "AI/Fixtures"),
              let data = try? Data(contentsOf: url) else {
            // Return default mock data if file not found
            return createDefaultMealSuggestions()
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(MealSuggestionResponse.self, from: data)
        return response.suggestions.map { json in
            MealSuggestion(
                title: json.title,
                description: json.description,
                cookTimeMinutes: json.cookTimeMinutes,
                requiredIngredients: json.requiredIngredients.map { 
                    IngredientInfo(name: $0.name, quantity: $0.quantity, unit: $0.unit)
                },
                missingIngredients: json.missingIngredients.map { 
                    IngredientInfo(name: $0.name, quantity: $0.quantity, unit: $0.unit)
                },
                steps: json.steps,
                estimatedMacros: MacroEstimate(
                    calories: json.estimatedMacros.calories,
                    proteinG: Double(json.estimatedMacros.proteinG),
                    carbsG: Double(json.estimatedMacros.carbsG),
                    fatG: Double(json.estimatedMacros.fatG)
                )
            )
        }
    }
    
    func loadWeeklyMealPlan() throws -> WeeklyMealPlan {
        guard let url = Bundle.main.url(forResource: "weekly_meal_plan", withExtension: "json", subdirectory: "AI/Fixtures"),
              let data = try? Data(contentsOf: url) else {
            return createDefaultWeeklyMealPlan()
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(WeeklyMealPlanResponse.self, from: data)
        
        // Convert to protocol type
        let days = response.days.map { dayPlanJSON in
            DayMealPlan(
                date: dayPlanJSON.date,
                meals: MealPlanMeals(
                    breakfast: dayPlanJSON.meals.breakfast?.title,
                    lunch: dayPlanJSON.meals.lunch?.title,
                    dinner: dayPlanJSON.meals.dinner?.title,
                    snack: dayPlanJSON.meals.snack?.title
                )
            )
        }
        
        let dailyMacroSummary = response.dailyMacroEstimates.map { estimateJSON in
            DailyMacroSummary(
                date: estimateJSON.date,
                calories: estimateJSON.calories,
                proteinG: Double(estimateJSON.proteinG),
                carbsG: Double(estimateJSON.carbsG),
                fatG: Double(estimateJSON.fatG)
            )
        }
        
        return WeeklyMealPlan(
            weekStart: response.weekStart,
            days: days,
            dailyMacroSummary: dailyMacroSummary,
            prepPlan: response.prepPlan
        )
    }
    
    func loadGroceryListSuggestions() throws -> [GroceryItemSuggestion] {
        guard let url = Bundle.main.url(forResource: "grocery_list", withExtension: "json", subdirectory: "AI/Fixtures"),
              let data = try? Data(contentsOf: url) else {
            return createDefaultGroceryList()
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(GroceryListSuggestionResponse.self, from: data)
        return response.items.map { json in
            GroceryItemSuggestion(
                name: json.name,
                quantity: json.quantity,
                unit: json.unit,
                reason: json.reason,
                priority: json.priority
            )
        }
    }
    
    // MARK: - Default Mock Data
    
    private func createDefaultMealSuggestions() -> [MealSuggestion] {
        return [
            MealSuggestion(
                title: "Simple Pasta with Tomato Sauce",
                description: "Quick and easy pasta dish using pantry staples",
                cookTimeMinutes: 20,
                requiredIngredients: [
                    IngredientInfo(name: "Pasta", quantity: 200, unit: "g"),
                    IngredientInfo(name: "Tomato Sauce", quantity: 400, unit: "ml")
                ],
                missingIngredients: [
                    IngredientInfo(name: "Garlic", quantity: 2, unit: "cloves")
                ],
                steps: [
                    "Boil water and cook pasta according to package instructions",
                    "Heat tomato sauce in a pan",
                    "Add garlic and simmer for 5 minutes",
                    "Drain pasta and mix with sauce",
                    "Serve hot"
                ],
                estimatedMacros: MacroEstimate(calories: 450, proteinG: 15.0, carbsG: 80.0, fatG: 8.0)
            )
        ]
    }
    
    private func createDefaultWeeklyMealPlan() -> WeeklyMealPlan {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        return WeeklyMealPlan(
            weekStart: today,
            days: [],
            dailyMacroSummary: [],
            prepPlan: ["Plan your meals for the week", "Prep ingredients in advance"]
        )
    }
    
    private func createDefaultGroceryList() -> [GroceryItemSuggestion] {
        return [
            GroceryItemSuggestion(name: "Milk", quantity: 2, unit: "L", reason: "low_stock", priority: 2),
            GroceryItemSuggestion(name: "Bread", quantity: 1, unit: "loaf", reason: "missing", priority: 1)
        ]
    }
}

