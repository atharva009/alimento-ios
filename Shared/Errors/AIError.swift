//
//  AIError.swift
//  Alimento
//
//  Created on Phase 7
//

import Foundation

enum AIError: LocalizedError, Equatable {
    case missingApiKey
    case networkFailure(message: String)
    case modelRefused(message: String)
    case malformedJSON(message: String)
    case decodingFailure(message: String)
    case rateLimited
    case invalidRequest(message: String)
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "AI features require the backend proxy. Configure BackendConfig.baseURL in Configuration/BackendConfig.swift and run the backend server."
        case .networkFailure(let message):
            return "Network error: \(message)"
        case .modelRefused(let message):
            return "AI model refused the request: \(message)"
        case .malformedJSON(let message):
            return "AI returned malformed output. Try again. Details: \(message)"
        case .decodingFailure(let message):
            return "Failed to decode AI response: \(message)"
        case .rateLimited:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        }
    }
}

