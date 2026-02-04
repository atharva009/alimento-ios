//
//  JSONGuardTests.swift
//  Alimento
//
//  Created on Phase 10
//

import XCTest
@testable import Alimento

final class JSONGuardTests: XCTestCase {
    
    // Mock GeminiClient for testing
    class MockGeminiClient: GeminiClientProtocol {
        var responses: [String] = []
        var callCount = 0
        
        func generateContent(prompt: String, systemInstruction: String?) async throws -> String {
            callCount += 1
            guard callCount <= responses.count else {
                throw AIError.networkFailure(message: "No more mock responses")
            }
            return responses[callCount - 1]
        }
    }
    
    struct TestModel: Decodable {
        let name: String
        let count: Int
    }
    
    func testJSONGuard_ValidJSON_FirstTry() async throws {
        let mockClient = MockGeminiClient()
        mockClient.responses = [
            """
            {"name": "Test", "count": 42}
            """
        ]
        
        let guard_ = JSONGuard(client: mockClient)
        
        let result: TestModel = try await guard_.fetchJSON(
            schemaDescription: "Test schema",
            modelType: TestModel.self,
            primaryPrompt: "Return test data",
            systemInstruction: "Return JSON only"
        )
        
        XCTAssertEqual(result.name, "Test")
        XCTAssertEqual(result.count, 42)
        XCTAssertEqual(mockClient.callCount, 1, "Should succeed on first try")
    }
    
    func testJSONGuard_MalformedJSON_RetryOnce() async throws {
        let mockClient = MockGeminiClient()
        mockClient.responses = [
            """
            This is not JSON at all
            """,
            """
            {"name": "Retry", "count": 99}
            """
        ]
        
        let guard_ = JSONGuard(client: mockClient)
        
        let result: TestModel = try await guard_.fetchJSON(
            schemaDescription: "Test schema",
            modelType: TestModel.self,
            primaryPrompt: "Return test data",
            systemInstruction: "Return JSON only"
        )
        
        XCTAssertEqual(result.name, "Retry")
        XCTAssertEqual(result.count, 99)
        XCTAssertEqual(mockClient.callCount, 2, "Should retry once after malformed JSON")
    }
    
    func testJSONGuard_MalformedJSON_BothFail() async throws {
        let mockClient = MockGeminiClient()
        mockClient.responses = [
            """
            This is not JSON
            """,
            """
            Still not valid JSON {invalid
            """
        ]
        
        let guard_ = JSONGuard(client: mockClient)
        
        do {
            let _: TestModel = try await guard_.fetchJSON(
                schemaDescription: "Test schema",
                modelType: TestModel.self,
                primaryPrompt: "Return test data",
                systemInstruction: "Return JSON only"
            )
            XCTFail("Should have thrown error after both attempts fail")
        } catch let error as AIError {
            if case .malformedJSON = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
        
        XCTAssertEqual(mockClient.callCount, 2, "Should retry exactly once")
    }
    
    func testJSONGuard_ValidJSON_WithWhitespace() async throws {
        let mockClient = MockGeminiClient()
        mockClient.responses = [
            """
            
            {"name": "Test", "count": 42}
            
            """
        ]
        
        let guard_ = JSONGuard(client: mockClient)
        
        let result: TestModel = try await guard_.fetchJSON(
            schemaDescription: "Test schema",
            modelType: TestModel.self,
            primaryPrompt: "Return test data",
            systemInstruction: "Return JSON only"
        )
        
        XCTAssertEqual(result.name, "Test")
        XCTAssertEqual(result.count, 42)
        XCTAssertEqual(mockClient.callCount, 1, "Should handle whitespace and succeed")
    }
    
    func testJSONGuard_JSONInMarkdown_ShouldFail() async throws {
        let mockClient = MockGeminiClient()
        mockClient.responses = [
            """
            ```json
            {"name": "Test", "count": 42}
            ```
            """,
            """
            {"name": "Retry", "count": 99}
            """
        ]
        
        let guard_ = JSONGuard(client: mockClient)
        
        // First attempt should fail (markdown), second should succeed
        let result: TestModel = try await guard_.fetchJSON(
            schemaDescription: "Test schema",
            modelType: TestModel.self,
            primaryPrompt: "Return test data",
            systemInstruction: "Return JSON only"
        )
        
        XCTAssertEqual(result.name, "Retry")
        XCTAssertEqual(result.count, 99)
        XCTAssertEqual(mockClient.callCount, 2, "Should retry after markdown-wrapped JSON")
    }
}

