//
//  InventoryServiceTests.swift
//  Alimento
//
//  Created on Phase 10
//

import XCTest
import SwiftData
@testable import Alimento

@MainActor
final class InventoryServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var inventoryService: InventoryService!
    
    override func setUp() {
        super.setUp()
        do {
            let schema = Schema([InventoryItem.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            inventoryService = InventoryServiceImpl(modelContext: modelContext)
        } catch {
            XCTFail("Failed to set up in-memory model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        inventoryService = nil
        super.tearDown()
    }
    
    // MARK: - Consume Item Tests
    
    func testConsumeItem_Success() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Milk",
            category: "Dairy",
            quantity: 2.0,
            unit: "L",
            location: "fridge",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 1.0
        )
        
        // Consume 0.5L
        try await inventoryService.consumeItem(item, amount: 0.5, unit: "L")
        
        // Verify quantity decreased
        let updatedItem = try await inventoryService.fetchAllItems().first
        XCTAssertEqual(updatedItem?.quantity, 1.5, accuracy: 0.01)
    }
    
    func testConsumeItem_ExactAmount() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Bread",
            category: "Grains",
            quantity: 1.0,
            unit: "loaf",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 0.5
        )
        
        // Consume entire amount
        try await inventoryService.consumeItem(item, amount: 1.0, unit: "loaf")
        
        // Verify quantity is zero
        let updatedItem = try await inventoryService.fetchAllItems().first
        XCTAssertEqual(updatedItem?.quantity, 0.0, accuracy: 0.01)
    }
    
    func testConsumeItem_InsufficientInventory() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Eggs",
            category: "Dairy",
            quantity: 6.0,
            unit: "pieces",
            location: "fridge",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 2.0
        )
        
        // Try to consume more than available
        do {
            try await inventoryService.consumeItem(item, amount: 10.0, unit: "pieces")
            XCTFail("Should have thrown insufficientInventory error")
        } catch let error as DomainError {
            if case .insufficientInventory(let itemName, let available, let requested) = error {
                XCTAssertEqual(itemName, "Eggs")
                XCTAssertEqual(available, 6.0, accuracy: 0.01)
                XCTAssertEqual(requested, 10.0, accuracy: 0.01)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
        
        // Verify quantity unchanged
        let unchangedItem = try await inventoryService.fetchAllItems().first
        XCTAssertEqual(unchangedItem?.quantity, 6.0, accuracy: 0.01)
    }
    
    func testConsumeItem_UnitMismatch() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Flour",
            category: "Grains",
            quantity: 1.0,
            unit: "kg",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 0.5
        )
        
        // Try to consume with wrong unit
        do {
            try await inventoryService.consumeItem(item, amount: 500.0, unit: "g")
            XCTFail("Should have thrown unitMismatch error")
        } catch let error as DomainError {
            if case .unitMismatch(let itemName, let expected, let provided) = error {
                XCTAssertEqual(itemName, "Flour")
                XCTAssertEqual(expected, "kg")
                XCTAssertEqual(provided, "g")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
        
        // Verify quantity unchanged
        let unchangedItem = try await inventoryService.fetchAllItems().first
        XCTAssertEqual(unchangedItem?.quantity, 1.0, accuracy: 0.01)
    }
    
    func testConsumeItem_CaseInsensitiveUnit() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Sugar",
            category: "Pantry",
            quantity: 2.0,
            unit: "kg",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 1.0
        )
        
        // Consume with different case
        try await inventoryService.consumeItem(item, amount: 0.5, unit: "KG")
        
        // Verify quantity decreased
        let updatedItem = try await inventoryService.fetchAllItems().first
        XCTAssertEqual(updatedItem?.quantity, 1.5, accuracy: 0.01)
    }
    
    // MARK: - Delete Item Tests
    
    func testDeleteItem_WithReferences() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Pasta",
            category: "Grains",
            quantity: 500.0,
            unit: "g",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 200.0
        )
        
        // Create a dish that references this item
        let dish = Dish(
            name: "Spaghetti",
            servings: 4,
            dateCooked: Date(),
            steps: nil
        )
        modelContext.insert(dish)
        
        let ingredient = DishIngredient(
            amountUsed: 300.0,
            unit: "g",
            dish: dish,
            inventoryItem: item,
            ingredientName: "Pasta"
        )
        modelContext.insert(ingredient)
        try modelContext.save()
        
        // Try to delete item
        do {
            try await inventoryService.deleteItem(item)
            XCTFail("Should have thrown validation error")
        } catch let error as DomainError {
            if case .validationFailed(let message) = error {
                XCTAssertTrue(message.contains("referenced"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testDeleteItem_NoReferences() async throws {
        // Create item
        let item = try await inventoryService.createItem(
            name: "Salt",
            category: "Pantry",
            quantity: 1.0,
            unit: "kg",
            location: "pantry",
            purchaseDate: Date(),
            expiryDate: nil,
            lowStockThreshold: 0.5
        )
        
        // Delete item
        try await inventoryService.deleteItem(item)
        
        // Verify item is deleted
        let items = try await inventoryService.fetchAllItems()
        XCTAssertTrue(items.isEmpty)
    }
}

