//
//  ChatMessage.swift
//  Alimento
//
//  Created on Phase 8
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct AssistantEvent: Identifiable, Codable {
    let id: UUID
    let type: EventType
    let toolName: String?
    let requestId: String?
    let timestamp: Date
    
    enum EventType: String, Codable {
        case toolCall
        case toolResult
        case confirmationRequired
        case confirmationApproved
        case confirmationCancelled
    }
    
    init(id: UUID = UUID(), type: EventType, toolName: String? = nil, requestId: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.toolName = toolName
        self.requestId = requestId
        self.timestamp = timestamp
    }
}

