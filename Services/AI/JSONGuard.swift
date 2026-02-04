//
//  JSONGuard.swift
//  Alimento
//
//  Created on Phase 7
//

import Foundation

// Protocol for Gemini client to enable testing
protocol GeminiClientProtocol {
    func generateContent(prompt: String, systemInstruction: String?) async throws -> String
}

extension GeminiClient: GeminiClientProtocol {
    // GeminiClient already implements generateContent, so no changes needed
}

final class JSONGuard {
    private let client: GeminiClientProtocol
    
    init(client: GeminiClientProtocol) {
        self.client = client
    }
    
    func fetchJSON<T: Decodable>(
        schemaDescription: String,
        modelType: T.Type,
        primaryPrompt: String,
        systemInstruction: String? = nil
    ) async throws -> T {
        // First attempt
        let firstResponse = try await client.generateContent(
            prompt: buildPrompt(schemaDescription: schemaDescription, userPrompt: primaryPrompt),
            systemInstruction: systemInstruction
        )
        
        if let decoded = try? decodeJSON(from: firstResponse, as: modelType) {
            return decoded
        }
        
        // Retry once with correction prompt
        let correctionPrompt = buildCorrectionPrompt(
            schemaDescription: schemaDescription,
            originalPrompt: primaryPrompt,
            failedResponse: firstResponse
        )
        
        let secondResponse = try await client.generateContent(
            prompt: correctionPrompt,
            systemInstruction: systemInstruction
        )
        
        if let decoded = try? decodeJSON(from: secondResponse, as: modelType) {
            return decoded
        }
        
        // Both attempts failed
        throw AIError.malformedJSON(message: "AI returned malformed output after retry. Please try again.")
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(schemaDescription: String, userPrompt: String) -> String {
        return """
        \(userPrompt)
        
        Return ONLY valid JSON that matches this schema:
        \(schemaDescription)
        
        Requirements:
        - Return ONLY JSON, no markdown
        - No code fences (```json or ```)
        - No backticks
        - No commentary or explanation
        - No extra keys beyond the schema
        - Ensure all required fields are present
        """
    }
    
    private func buildCorrectionPrompt(
        schemaDescription: String,
        originalPrompt: String,
        failedResponse: String
    ) -> String {
        return """
        The previous response was invalid JSON. Please return ONLY valid JSON that matches this schema:
        \(schemaDescription)
        
        Original request: \(originalPrompt)
        
        Previous invalid response: \(failedResponse)
        
        Requirements:
        - Return ONLY JSON, no markdown
        - No code fences (```json or ```)
        - No backticks
        - No commentary or explanation
        - No extra keys beyond the schema
        - Ensure all required fields are present
        - Fix any JSON syntax errors
        """
    }
    
    private func decodeJSON<T: Decodable>(from text: String, as type: T.Type) throws -> T {
        // Strip leading/trailing whitespace
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code fences if present
        var cleaned = trimmed
        if cleaned.hasPrefix("```") {
            // Find the end of the opening fence
            if let firstNewline = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: firstNewline)...])
            } else if cleaned.hasPrefix("```json") {
                cleaned = String(cleaned.dropFirst(7))
            } else {
                cleaned = String(cleaned.dropFirst(3))
            }
        }
        
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find JSON object/array boundaries
        if let jsonStart = cleaned.firstIndex(of: "{"),
           let jsonEnd = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[jsonStart...jsonEnd])
        } else if let jsonStart = cleaned.firstIndex(of: "["),
                  let jsonEnd = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[jsonStart...jsonEnd])
        }
        
        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.malformedJSON(message: "Could not convert text to data")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw AIError.decodingFailure(message: error.localizedDescription)
        }
    }
}

