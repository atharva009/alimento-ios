//
//  DomainError.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation

enum DomainError: LocalizedError, Equatable {
    case negativeQuantity
    case invalidLocation(location: String)
    case invalidMealType(mealType: String)
    case invalidDishData(message: String)
    case validationFailed(message: String)
    case persistenceError(message: String)
    case inventoryItemNotFound
    case dishNotFound
    case plannedMealNotFound
    case groceryListNotFound
    case groceryItemNotFound
    case unitMismatch(itemName: String, expected: String, provided: String)
    case insufficientInventory(itemName: String, available: Double, requested: Double)
    case invalidDate
    case invalidGroceryItem(reason: String)
    case mergeFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .negativeQuantity:
            return "Quantity cannot be negative"
        case .invalidLocation(let location):
            return "Invalid location: \(location). Must be one of: pantry, fridge, freezer"
        case .invalidMealType(let mealType):
            return "Invalid meal type: \(mealType). Must be one of: breakfast, lunch, dinner, snack"
        case .invalidDishData(let message):
            return "Invalid dish data: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .persistenceError(let message):
            return "Database error: \(message)"
        case .inventoryItemNotFound:
            return "Inventory item not found"
        case .dishNotFound:
            return "Dish not found"
        case .plannedMealNotFound:
            return "Planned meal not found"
        case .groceryListNotFound:
            return "Grocery list not found"
        case .groceryItemNotFound:
            return "Grocery item not found"
        case .unitMismatch(let itemName, let expected, let provided):
            return "Unit mismatch for \(itemName): expected \(expected), but provided \(provided)"
        case .insufficientInventory(let itemName, let available, let requested):
            return "Insufficient inventory for \(itemName): available \(available), but requested \(requested)"
        case .invalidDate:
            return "Invalid date"
        case .invalidGroceryItem(let reason):
            return "Invalid grocery item: \(reason)"
        case .mergeFailed(let reason):
            return "Failed to merge items: \(reason)"
        }
    }
}

