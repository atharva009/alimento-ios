//
//  AIServiceTests.swift
//  Alimento
//
//  Created on Phase 7
//

import XCTest
@testable import Alimento

final class AIServiceTests: XCTestCase {
    
    func testMealSuggestionDecoding() throws {
        // Load fixture
        guard let url = Bundle.main.url(forResource: "meal_suggestions", withExtension: "json", subdirectory: "AI/Fixtures"),
              let data = try? Data(contentsOf: url) else {
            XCTFail("Could not load meal_suggestions.json fixture")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        let response = try decoder.decode(MealSuggestionResponse.self, from: data)
        
        // Validate
        XCTAssertFalse(response.suggestions.isEmpty, "Should have suggestions")
        XCTAssertGreaterThanOrEqual(response.suggestions.count, 1, "Should have at least 1 suggestion")
        
        let first = response.suggestions[0]
        XCTAssertFalse(first.title.isEmpty, "Title should not be empty")
        XCTAssertGreaterThan(first.cookTimeMinutes, 0, "Cook time should be positive")
        XCTAssertFalse(first.steps.isEmpty, "Should have cooking steps")
        XCTAssertFalse(first.estimatedMacros.calories == 0, "Should have calories")
    }
    
    func testWeeklyMealPlanDecoding() throws {
        // Load fixture
        guard let url = Bundle.main.url(forResource: "weekly_meal_plan", withExtension: "json", subdirectory: "AI/Fixtures"),
              let data = try? Data(contentsOf: url) else {
            XCTFail("Could not load weekly_meal_plan.json fixture")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        let response = try decoder.decode(WeeklyMealPlanResponse.self, from: data)
        
        // Validate
        XCTAssertFalse(response.weekStart.isEmpty, "Week start should not be empty")
        XCTAssertFalse(response.days.isEmpty, "Should have days")
        XCTAssertFalse(response.dailyMacroEstimates.isEmpty, "Should have macro estimates")
    }
    
    func testGroceryListDecoding() throws {
        // Load fixture
        guard let url = Bundle.main.url(forResource: "grocery_list", withExtension: "json", subdirectory: "AI/Fixtures"),
              let data = try? Data(contentsOf: url) else {
            XCTFail("Could not load grocery_list.json fixture")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        let response = try decoder.decode(GroceryListSuggestionResponse.self, from: data)
        
        // Validate
        XCTAssertFalse(response.items.isEmpty, "Should have items")
        
        let first = response.items[0]
        XCTAssertFalse(first.name.isEmpty, "Name should not be empty")
        XCTAssertGreaterThan(first.quantity, 0, "Quantity should be positive")
        XCTAssertFalse(first.unit.isEmpty, "Unit should not be empty")
        XCTAssertGreaterThanOrEqual(first.priority, 1, "Priority should be at least 1")
        XCTAssertLessThanOrEqual(first.priority, 3, "Priority should be at most 3")
    }
    
    func testPromptBuilderProducesNonEmptyStrings() {
        let inventory = [
            InventorySummary(name: "Tomato", quantity: 2.0, unit: "kg", location: "fridge", expiryDate: nil, lowStockThreshold: 1.0)
        ]
        
        let preferences = UserPreferences(
            dietaryPreference: "vegetarian",
            allergies: [],
            dislikedIngredients: [],
            preferredCuisines: ["Italian"],
            maxCookTimeMinutes: 30,
            targetCaloriesPerDay: 2000,
            targetProteinG: 100,
            targetCarbsG: 250,
            targetFatG: 60
        )
        
        let prompt = PromptBuilder.buildMealSuggestionPrompt(inventory: inventory, preferences: preferences)
        
        XCTAssertFalse(prompt.isEmpty, "Prompt should not be empty")
        XCTAssertTrue(prompt.contains("JSON"), "Prompt should mention JSON")
        XCTAssertTrue(prompt.lowercased().contains("only"), "Prompt should include 'only' constraint")
    }
    
    func testAIConfigurationMode() {
        let config = AIConfiguration.shared
        
        // Mode should be deterministic based on API key presence
        if config.hasAPIKey {
            XCTAssertEqual(config.mode, .live, "Mode should be live when API key is present")
        } else {
            XCTAssertEqual(config.mode, .mock, "Mode should be mock when API key is missing")
        }
    }
}

