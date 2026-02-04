//
//  AIService.swift
//  Alimento
//
//  Created on Phase 1
//
//  Protocol for AI (Gemini) integration. Response DTOs live in Models/AI/AIModels.swift.
//

import Foundation
import SwiftData

/// Protocol for AI (Gemini) integration operations
protocol AIService {
    // Meal suggestions
    func suggestMealsFromInventory(
        inventoryItems: [InventoryItem],
        preferences: UserProfile,
        timeConstraint: Int?
    ) async throws -> [MealSuggestion]

    // Meal planning
    func generateWeeklyMealPlan(
        preferences: UserProfile,
        mealsPerDay: Int,
        busyDays: [Date]?
    ) async throws -> WeeklyMealPlan

    // Grocery list generation
    func generateGroceryList(
        plannedMeals: [PlannedMeal],
        currentInventory: [InventoryItem],
        lowStockItems: [InventoryItem]
    ) async throws -> [GroceryItemSuggestion]

    // Assistant chat
    func sendChatMessage(
        message: String,
        conversationHistory: [AIServiceChatMessage]
    ) async throws -> ChatResponse
}
