//
//  DishLogServiceTests.swift
//  Alimento
//
//  Created on Phase 10
//

import XCTest
import SwiftData
@testable import Alimento

@MainActor
final class DishLogServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var inventoryService: InventoryService!
    var dishLogService: DishLogService!
    
    override func setUp() {
        super.setUp()
        do {
            let schema = Schema([InventoryItem.self, Dish.self, DishIngredient.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            inventoryService = InventoryServiceImpl(modelContext: modelContext)
            dishLogService = DishLogServiceImpl(modelContext: modelContext, inventoryService: inventoryService)
        } catch {
            XCTFail("Failed to set up in-memory model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        inventoryService = nil
        dishLogService = nil
        super.tearDown()
    }
    
    // MARK: - Transactional Behavior Tests
    
    func testLogDish_AllOrNothing_Success() async throws {
        // Create inventory items
        let pasta = try await inventoryService.createItem(
            name: "Pasta",
            category: "Grains",
            quantity: 500.0,
            unit: "g",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 200.0
        )
        
        let sauce = try await inventoryService.createItem(
            name: "Tomato Sauce",
            category: "Pantry",
            quantity: 400.0,
            unit: "g",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 200.0
        )
        
        // Log dish with both ingredients
        let dish = try await dishLogService.logDish(
            name: "Spaghetti",
            servings: 4,
            dateCooked: Date(),
            steps: "Cook pasta, add sauce",
            ingredients: [
                (inventoryItem: pasta, name: "Pasta", amount: 300.0, unit: "g"),
                (inventoryItem: sauce, name: "Tomato Sauce", amount: 200.0, unit: "g")
            ]
        )
        
        // Verify dish was created
        XCTAssertNotNil(dish)
        XCTAssertEqual(dish.name, "Spaghetti")
        
        // Verify ingredients were created
        let ingredients = dish.ingredients ?? []
        XCTAssertEqual(ingredients.count, 2)
        
        // Verify inventory was decremented
        let updatedPasta = try await inventoryService.fetchAllItems().first { $0.name == "Pasta" }
        XCTAssertEqual(updatedPasta?.quantity, 200.0, accuracy: 0.01)
        
        let updatedSauce = try await inventoryService.fetchAllItems().first { $0.name == "Tomato Sauce" }
        XCTAssertEqual(updatedSauce?.quantity, 200.0, accuracy: 0.01)
    }
    
    func testLogDish_AllOrNothing_Failure() async throws {
        // Create inventory items
        let pasta = try await inventoryService.createItem(
            name: "Pasta",
            category: "Grains",
            quantity: 500.0,
            unit: "g",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 200.0
        )
        
        let sauce = try await inventoryService.createItem(
            name: "Tomato Sauce",
            category: "Pantry",
            quantity: 100.0, // Not enough for 200g
            unit: "g",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 200.0
        )
        
        // Try to log dish - should fail on second ingredient
        do {
            _ = try await dishLogService.logDish(
                name: "Spaghetti",
                servings: 4,
                dateCooked: Date(),
                steps: nil,
                ingredients: [
                    (inventoryItem: pasta, name: "Pasta", amount: 300.0, unit: "g"),
                    (inventoryItem: sauce, name: "Tomato Sauce", amount: 200.0, unit: "g") // More than available
                ]
            )
            XCTFail("Should have thrown error")
        } catch {
            // Expected error
        }
        
        // Verify NO dish was created
        let dishes = try await dishLogService.fetchAllDishes()
        XCTAssertTrue(dishes.isEmpty, "Dish should not be created on failure")
        
        // Verify NO inventory was decremented (rollback)
        let unchangedPasta = try await inventoryService.fetchAllItems().first { $0.name == "Pasta" }
        XCTAssertEqual(unchangedPasta?.quantity, 500.0, accuracy: 0.01, "Pasta should not be consumed on failure")
        
        let unchangedSauce = try await inventoryService.fetchAllItems().first { $0.name == "Tomato Sauce" }
        XCTAssertEqual(unchangedSauce?.quantity, 100.0, accuracy: 0.01, "Sauce should not be consumed on failure")
    }
    
    func testLogDish_WithNonInventoryIngredients() async throws {
        // Create one inventory item
        let pasta = try await inventoryService.createItem(
            name: "Pasta",
            category: "Grains",
            quantity: 500.0,
            unit: "g",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 200.0
        )
        
        // Log dish with both inventory and non-inventory ingredients
        let dish = try await dishLogService.logDish(
            name: "Pasta with Herbs",
            servings: 2,
            dateCooked: Date(),
            steps: nil,
            ingredients: [
                (inventoryItem: pasta, name: "Pasta", amount: 200.0, unit: "g"),
                (inventoryItem: nil, name: "Fresh Basil", amount: 10.0, unit: "g") // Not in inventory
            ]
        )
        
        // Verify dish was created
        XCTAssertNotNil(dish)
        
        // Verify ingredients were created
        let ingredients = dish.ingredients ?? []
        XCTAssertEqual(ingredients.count, 2)
        
        // Verify only inventory item was decremented
        let updatedPasta = try await inventoryService.fetchAllItems().first { $0.name == "Pasta" }
        XCTAssertEqual(updatedPasta?.quantity, 300.0, accuracy: 0.01)
    }
}

