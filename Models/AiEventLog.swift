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
    var eventType: String // "suggestion", "plan", "grocery", "chat"
    var timestamp: Date
    var inputSummary: String? // Optional summary of inputs
    var responseSummary: String? // Optional summary of AI response
    var tokensUsed: Int? // Optional token count
    var cost: Double? // Optional cost in currency
    
    init(
        eventType: String,
        timestamp: Date = Date(),
        inputSummary: String? = nil,
        responseSummary: String? = nil,
        tokensUsed: Int? = nil,
        cost: Double? = nil
    ) {
        self.eventType = eventType
        self.timestamp = timestamp
        self.inputSummary = inputSummary
        self.responseSummary = responseSummary
        self.tokensUsed = tokensUsed
        self.cost = cost
    }
}

