//
//  AiEventLog.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class AiEventLog {
    var timestamp: Date
    var featureType: String // "suggest_meals", "generate_plan", "generate_grocery", "assistant_chat", "tool_call"
    var tokenEstimate: Int? // Optional token count estimate
    var success: Bool
    var errorMessage: String? // Optional error message (no raw prompts stored)
    
    // Metadata
    var createdAt: Date
    
    init(
        timestamp: Date = Date(),
        featureType: String,
        tokenEstimate: Int? = nil,
        success: Bool,
        errorMessage: String? = nil
    ) {
        self.timestamp = timestamp
        self.featureType = featureType
        self.tokenEstimate = tokenEstimate
        self.success = success
        self.errorMessage = errorMessage
        self.createdAt = Date()
    }
}

