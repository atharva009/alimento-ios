//
//  AIServiceImpl.swift
//  Alimento
//
//  Created on Phase 7
//

import Foundation
import SwiftData

@MainActor
final class AIServiceImpl: AIService {
    private let config: AIConfiguration
    private var client: GeminiClient?
    private var jsonGuard: JSONGuard?
    private let mockLoader: MockResponseLoader
    
    // Rate limiting
    private var lastRequestTime: Date?
    private let requestCooldown: TimeInterval = 3.0
    private var requestCount: Int = 0
    private let maxRequestsPerSession = 50
    
    init() {
        self.config = AIConfiguration.shared
        self.mockLoader = MockResponseLoader()
        
        if config.mode == AIMode.live {
            do {
                let backendURL = try config.getBackendBaseURL()
                let geminiClient = GeminiClient(backendBaseURL: backendURL)
                self.client = geminiClient
                self.jsonGuard = JSONGuard(client: geminiClient)
            } catch {
                // Fallback to mock mode if backend is not configured
                // No logging in production - mock mode is a valid fallback
            }
        }
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit() throws {
        if let lastTime = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastTime)
            if timeSinceLastRequest < requestCooldown {
                throw AIError.rateLimited
            }
        }
        
        if requestCount >= maxRequestsPerSession {
            throw AIError.rateLimited
        }
        
        requestCount += 1
        lastRequestTime = Date()
    }
    
    // MARK: - Meal Suggestions
    
    func suggestMealsFromInventory(
        inventoryItems: [InventoryItem],
        preferences: UserProfile,
        timeConstraint: Int?
    ) async throws -> [MealSuggestion] {
        try checkRateLimit()
        
        if config.mode == AIMode.mock {
            return try mockLoader.loadMealSuggestions()
        }
        
        guard let jsonGuard = jsonGuard else {
            throw AIError.missingApiKey
        }
        
        // Convert inventory to summary format
        let inventorySummary = inventoryItems.map { item in
            InventorySummary(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                location: item.location,
                expiryDate: item.expiryDate,
                lowStockThreshold: item.lowStockThreshold
            )
        }
        
        // Convert preferences
        let userPreferences = UserPreferences(
            dietaryPreference: preferences.dietaryPreference,
            allergies: preferences.allergies + (preferences.allergiesFreeText.isEmpty ? [] : [preferences.allergiesFreeText]),
            dislikedIngredients: preferences.dislikedIngredients,
            preferredCuisines: preferences.cuisinePreferences,
            maxCookTimeMinutes: timeConstraint ?? preferences.preferredCookingTimeMinutes,
            targetCaloriesPerDay: preferences.calorieTarget ?? 0,
            targetProteinG: Int(preferences.proteinTargetG ?? 0),
            targetCarbsG: Int(preferences.carbsTargetG ?? 0),
            targetFatG: Int(preferences.fatTargetG ?? 0)
        )
        
        let prompt = PromptBuilder.buildMealSuggestionPrompt(
            inventory: inventorySummary,
            preferences: userPreferences
        )
        
        let schema = """
        {
          "suggestions": [
            {
              "title": "string",
              "description": "string",
              "cookTimeMinutes": number,
              "requiredIngredients": [
                {
                  "name": "string",
                  "quantity": number,
                  "unit": "string"
                }
              ],
              "missingIngredients": [
                {
                  "name": "string",
                  "quantity": number,
                  "unit": "string"
                }
              ],
              "steps": ["string"],
              "estimatedMacros": {
                "calories": number,
                "proteinG": number,
                "carbsG": number,
                "fatG": number
              },
              "disclaimer": "string"
            }
          ]
        }
        """
        
        let response: MealSuggestionResponse = try await jsonGuard.fetchJSON(
            schemaDescription: schema,
            modelType: MealSuggestionResponse.self,
            primaryPrompt: prompt,
            systemInstruction: PromptBuilder.systemInstruction
        )
        
        // Convert to protocol types
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
    
    // MARK: - Weekly Meal Plan
    
    func generateWeeklyMealPlan(
        preferences: UserProfile,
        mealsPerDay: Int,
        busyDays: [Date]?
    ) async throws -> WeeklyMealPlan {
        try checkRateLimit()
        
        if config.mode == AIMode.mock {
            return try mockLoader.loadWeeklyMealPlan()
        }
        
        guard let jsonGuard = jsonGuard else {
            throw AIError.missingApiKey
        }
        
        let weekStart = Calendar.current.startOfDay(for: Date())
        
        let userPreferences = UserPreferences(
            dietaryPreference: preferences.dietaryPreference,
            allergies: preferences.allergies + (preferences.allergiesFreeText.isEmpty ? [] : [preferences.allergiesFreeText]),
            dislikedIngredients: preferences.dislikedIngredients,
            preferredCuisines: preferences.cuisinePreferences,
            maxCookTimeMinutes: preferences.preferredCookingTimeMinutes,
            targetCaloriesPerDay: preferences.calorieTarget ?? 0,
            targetProteinG: Int(preferences.proteinTargetG ?? 0),
            targetCarbsG: Int(preferences.carbsTargetG ?? 0),
            targetFatG: Int(preferences.fatTargetG ?? 0)
        )
        
        let prompt = PromptBuilder.buildWeeklyMealPlanPrompt(
            weekStart: weekStart,
            preferences: userPreferences,
            mealsPerDay: mealsPerDay
        )
        
        let schema = """
        {
          "weekStart": "string (ISO date)",
          "days": [
            {
              "date": "string (ISO date)",
              "meals": {
                "breakfast": {
                  "title": "string",
                  "description": "string (optional)",
                  "cookTimeMinutes": number (optional),
                  "ingredients": [
                    {
                      "name": "string",
                      "quantity": number,
                      "unit": "string"
                    }
                  ] (optional)
                } (optional),
                "lunch": { ... } (optional),
                "dinner": { ... } (optional),
                "snack": { ... } (optional)
              }
            }
          ],
          "dailyMacroEstimates": [
            {
              "date": "string (ISO date)",
              "calories": number,
              "proteinG": number,
              "carbsG": number,
              "fatG": number
            }
          ],
          "prepPlan": ["string"],
          "disclaimer": "string"
        }
        """
        
        let response: WeeklyMealPlanResponse = try await jsonGuard.fetchJSON(
            schemaDescription: schema,
            modelType: WeeklyMealPlanResponse.self,
            primaryPrompt: prompt,
            systemInstruction: PromptBuilder.systemInstruction
        )
        
        // Convert to protocol type
        return convertToWeeklyMealPlan(response)
    }
    
    // MARK: - Grocery List Generation
    
    func generateGroceryList(
        plannedMeals: [PlannedMeal],
        currentInventory: [InventoryItem],
        lowStockItems: [InventoryItem]
    ) async throws -> [GroceryItemSuggestion] {
        try checkRateLimit()
        
        if config.mode == AIMode.mock {
            return try mockLoader.loadGroceryListSuggestions()
        }
        
        guard let jsonGuard = jsonGuard else {
            throw AIError.missingApiKey
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let plannedMealsSummary = plannedMeals.map { meal in
            PlannedMealSummary(
                title: meal.title,
                date: formatter.string(from: meal.date),
                mealType: meal.mealType
            )
        }
        
        let inventorySummary = currentInventory.map { item in
            InventorySummary(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                location: item.location,
                expiryDate: item.expiryDate,
                lowStockThreshold: item.lowStockThreshold
            )
        }
        
        let lowStockSummary = lowStockItems.map { item in
            InventorySummary(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                location: item.location,
                expiryDate: item.expiryDate,
                lowStockThreshold: item.lowStockThreshold
            )
        }
        
        let prompt = PromptBuilder.buildGroceryListPrompt(
            plannedMeals: plannedMealsSummary,
            inventory: inventorySummary,
            lowStockItems: lowStockSummary
        )
        
        let schema = """
        {
          "items": [
            {
              "name": "string",
              "quantity": number,
              "unit": "string",
              "reason": "string (missing, low_stock, or staple)",
              "priority": number (1=high, 2=medium, 3=low)
            }
          ],
          "disclaimer": "string"
        }
        """
        
        let response: GroceryListSuggestionResponse = try await jsonGuard.fetchJSON(
            schemaDescription: schema,
            modelType: GroceryListSuggestionResponse.self,
            primaryPrompt: prompt,
            systemInstruction: PromptBuilder.systemInstruction
        )
        
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
    
    // MARK: - Assistant Chat (Not implemented in Phase 7)
    
    func sendChatMessage(
        message: String,
        conversationHistory: [AIServiceChatMessage]
    ) async throws -> ChatResponse {
        throw AIError.invalidRequest(message: "Chat functionality not available in Phase 7")
    }
    
    // MARK: - Helper Methods
    
    private func convertToWeeklyMealPlan(_ response: WeeklyMealPlanResponse) -> WeeklyMealPlan {
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
}

