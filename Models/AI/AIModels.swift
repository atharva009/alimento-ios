//
//  AIModels.swift
//  Alimento
//
//  DTOs and shared types for AI (Gemini) responses and assistant chat.
//  Used by AIService, AIServiceImpl, Assistant, and tests.
//

import Foundation

// MARK: - Meal suggestions

struct MealSuggestion: Codable {
    let title: String
    let description: String
    let cookTimeMinutes: Int
    let requiredIngredients: [IngredientInfo]
    let missingIngredients: [IngredientInfo]
    let steps: [String]
    let estimatedMacros: MacroEstimate
}

struct IngredientInfo: Codable {
    let name: String
    let quantity: Double
    let unit: String
}

struct MacroEstimate: Codable {
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

// MARK: - Weekly meal plan

struct WeeklyMealPlan: Codable {
    let weekStart: String // ISO date string
    let days: [DayMealPlan]
    let dailyMacroSummary: [DailyMacroSummary]
    let prepPlan: [String]
}

struct DayMealPlan: Codable {
    let date: String // ISO date string
    let meals: MealPlanMeals
}

struct MealPlanMeals: Codable {
    let breakfast: String?
    let lunch: String?
    let dinner: String?
    let snack: String?
}

struct DailyMacroSummary: Codable {
    let date: String // ISO date string
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

// MARK: - Grocery suggestions

struct GroceryItemSuggestion: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let reason: String
    let priority: Int
}

// MARK: - Assistant chat

struct AIServiceChatMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
}

struct ChatResponse: Codable {
    let type: String // "message" or "toolCall"
    let content: String? // For type "message"
    let tool: String? // For type "toolCall"
    let args: [String: AnyCodable]? // For type "toolCall"
}

// MARK: - Dynamic JSON (tool args, etc.)

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}
