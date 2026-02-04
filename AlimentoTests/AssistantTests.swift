//
//  AssistantTests.swift
//  Alimento
//
//  Created on Phase 8
//

import XCTest
@testable import Alimento

final class AssistantTests: XCTestCase {
    
    // MARK: - Assistant Response Decoding
    
    func testDecodeMessageResponse() throws {
        let json = """
        {
          "type": "message",
          "content": "Hello, how can I help you?"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AssistantResponse.self, from: data)
        
        XCTAssertEqual(response.type, .message)
        XCTAssertEqual(response.content, "Hello, how can I help you?")
        XCTAssertNil(response.tool)
        XCTAssertNil(response.args)
    }
    
    func testDecodeToolCallResponse() throws {
        let json = """
        {
          "type": "toolCall",
          "tool": "addInventoryItem",
          "args": {
            "name": "Milk",
            "quantity": 2.0,
            "unit": "L",
            "location": "fridge"
          },
          "requestId": "123e4567-e89b-12d3-a456-426614174000"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AssistantResponse.self, from: data)
        
        XCTAssertEqual(response.type, .toolCall)
        XCTAssertEqual(response.tool, "addInventoryItem")
        XCTAssertNotNil(response.args)
        XCTAssertEqual(response.requestId, "123e4567-e89b-12d3-a456-426614174000")
    }
    
    func testDecodeToolCallWithConfirmation() throws {
        let json = """
        {
          "type": "toolCall",
          "tool": "updateInventoryQuantity",
          "args": {
            "itemId": "123e4567-e89b-12d3-a456-426614174000",
            "delta": -5.0
          },
          "requestId": "123e4567-e89b-12d3-a456-426614174001",
          "confirmationRequired": true,
          "confirmationMessage": "This will reduce the quantity. Continue?"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AssistantResponse.self, from: data)
        
        XCTAssertEqual(response.type, .toolCall)
        XCTAssertTrue(response.confirmationRequired ?? false)
        XCTAssertEqual(response.confirmationMessage, "This will reduce the quantity. Continue?")
    }
    
    // MARK: - Tool Args Decoding
    
    func testDecodeAddInventoryItemArgs() throws {
        let json = """
        {
          "name": "Tomatoes",
          "category": "Vegetables",
          "quantity": 1.5,
          "unit": "kg",
          "location": "fridge",
          "expiryDate": "2024-12-31"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let args = try decoder.decode(AddInventoryItemArgs.self, from: data)
        
        XCTAssertEqual(args.name, "Tomatoes")
        XCTAssertEqual(args.category, "Vegetables")
        XCTAssertEqual(args.quantity, 1.5)
        XCTAssertEqual(args.unit, "kg")
        XCTAssertEqual(args.location, "fridge")
        XCTAssertEqual(args.expiryDate, "2024-12-31")
    }
    
    func testDecodeUpdateInventoryQuantityArgs() throws {
        let json = """
        {
          "itemId": "123e4567-e89b-12d3-a456-426614174000",
          "delta": 2.5
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let args = try decoder.decode(UpdateInventoryQuantityArgs.self, from: data)
        
        XCTAssertEqual(args.itemId, "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(args.delta, 2.5)
    }
    
    func testDecodeCreatePlannedMealArgs() throws {
        let json = """
        {
          "date": "2024-12-25",
          "mealType": "dinner",
          "title": "Christmas Dinner"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let args = try decoder.decode(CreatePlannedMealArgs.self, from: data)
        
        XCTAssertEqual(args.date, "2024-12-25")
        XCTAssertEqual(args.mealType, "dinner")
        XCTAssertEqual(args.title, "Christmas Dinner")
    }
    
    func testDecodeGenerateGroceryListArgs() throws {
        let json = """
        {
          "daysAhead": 7,
          "includePlannedMeals": true,
          "includeLowStock": true
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let args = try decoder.decode(GenerateGroceryListArgs.self, from: data)
        
        XCTAssertEqual(args.daysAhead, 7)
        XCTAssertTrue(args.includePlannedMeals)
        XCTAssertTrue(args.includeLowStock)
    }
    
    func testDecodeLogCookedDishArgs() throws {
        let json = """
        {
          "name": "Pasta",
          "servings": 4,
          "dateCooked": "2024-12-22",
          "ingredientsUsed": [
            {
              "inventoryItemId": "123e4567-e89b-12d3-a456-426614174000",
              "quantity": 500.0,
              "unit": "g"
            }
          ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let args = try decoder.decode(LogCookedDishArgs.self, from: data)
        
        XCTAssertEqual(args.name, "Pasta")
        XCTAssertEqual(args.servings, 4)
        XCTAssertEqual(args.dateCooked, "2024-12-22")
        XCTAssertEqual(args.ingredientsUsed.count, 1)
        XCTAssertEqual(args.ingredientsUsed[0].quantity, 500.0)
    }
    
    // MARK: - Tool Validation
    
    func testValidateAddInventoryItemArgs() {
        let validArgs = AddInventoryItemArgs(
            name: "Milk",
            category: "Dairy",
            quantity: 2.0,
            unit: "L",
            location: "fridge",
            expiryDate: nil
        )
        
        XCTAssertNoThrow(try validArgs.validate())
    }
    
    func testValidateAddInventoryItemArgsFailsWithEmptyName() {
        let invalidArgs = AddInventoryItemArgs(
            name: "",
            category: nil,
            quantity: 2.0,
            unit: "L",
            location: "fridge",
            expiryDate: nil
        )
        
        XCTAssertThrowsError(try invalidArgs.validate()) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
    
    func testValidateAddInventoryItemArgsFailsWithInvalidLocation() {
        let invalidArgs = AddInventoryItemArgs(
            name: "Milk",
            category: nil,
            quantity: 2.0,
            unit: "L",
            location: "invalid",
            expiryDate: nil
        )
        
        XCTAssertThrowsError(try invalidArgs.validate()) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
    
    func testValidateUpdateInventoryQuantityArgsFailsWithZeroDelta() {
        let invalidArgs = UpdateInventoryQuantityArgs(itemId: "test-id", delta: 0.0)
        
        XCTAssertThrowsError(try invalidArgs.validate()) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
    
    func testValidateCreatePlannedMealArgsFailsWithoutTitleOrDishId() {
        let invalidArgs = CreatePlannedMealArgs(
            date: "2024-12-25",
            mealType: "dinner",
            title: nil,
            dishId: nil
        )
        
        XCTAssertThrowsError(try invalidArgs.validate()) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
    
    func testValidateGenerateGroceryListArgsFailsWithInvalidDaysAhead() {
        let invalidArgs = GenerateGroceryListArgs(
            daysAhead: 20,
            includePlannedMeals: true,
            includeLowStock: true
        )
        
        XCTAssertThrowsError(try invalidArgs.validate()) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
    
    func testValidateLogCookedDishArgsFailsWithEmptyName() {
        let invalidArgs = LogCookedDishArgs(
            name: "",
            servings: 4,
            dateCooked: "2024-12-22",
            ingredientsUsed: []
        )
        
        XCTAssertThrowsError(try invalidArgs.validate()) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
    
    // MARK: - Tool Registry
    
    func testToolRegistryRoutesCorrectly() {
        let mockExecutor = MockToolExecutor()
        let executors: [ToolName: ToolExecutor] = [
            .addInventoryItem: mockExecutor
        ]
        let registry = ToolRegistry(executors: executors)
        
        let args: [String: AnyCodable] = [
            "name": AnyCodable("Test"),
            "quantity": AnyCodable(1.0),
            "unit": AnyCodable("kg"),
            "location": AnyCodable("pantry")
        ]
        
        // Should not throw for valid tool
        XCTAssertNoThrow(try registry.validateToolCall(tool: "addInventoryItem", args: args))
    }
    
    func testToolRegistryFailsForUnknownTool() {
        let registry = ToolRegistry(executors: [:])
        let args: [String: AnyCodable] = [:]
        
        XCTAssertThrowsError(try registry.validateToolCall(tool: "unknownTool", args: args)) { error in
            XCTAssertTrue(error is ToolValidationError)
        }
    }
}

// MARK: - Mock Executor

class MockToolExecutor: ToolExecutor {
    func execute(args: [String: AnyCodable], context: ToolExecutionContext) async throws -> [String: AnyCodable] {
        return ["success": AnyCodable(true)]
    }
}

