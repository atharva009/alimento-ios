//
//  AssistantResponse.swift
//  Alimento
//
//  Created on Phase 8
//

import Foundation

// MARK: - Assistant Response Envelope

struct AssistantResponse: Decodable {
    let type: ResponseType
    let content: String?
    let tool: String?
    let args: [String: AnyCodable]?
    let requestId: String?
    let confirmationRequired: Bool?
    let confirmationMessage: String?
    
    enum ResponseType: String, Decodable {
        case message
        case toolCall
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case content
        case tool
        case args
        case requestId
        case confirmationRequired
        case confirmationMessage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ResponseType.self, forKey: .type)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        tool = try container.decodeIfPresent(String.self, forKey: .tool)
        args = try container.decodeIfPresent([String: AnyCodable].self, forKey: .args)
        requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
        confirmationRequired = try container.decodeIfPresent(Bool.self, forKey: .confirmationRequired)
        confirmationMessage = try container.decodeIfPresent(String.self, forKey: .confirmationMessage)
        
        // Validation
        if type == .toolCall {
            guard let tool = tool, !tool.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .tool, in: container, debugDescription: "toolCall must have non-empty tool name")
            }
            guard let requestId = requestId, !requestId.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .requestId, in: container, debugDescription: "toolCall must have non-empty requestId")
            }
        }
    }
}

// MARK: - Tool Result

struct ToolResult: Codable {
    let requestId: String
    let tool: String
    let success: Bool
    let result: [String: AnyCodable]?
    let error: String?
    
    init(requestId: String, tool: String, success: Bool, result: [String: AnyCodable]? = nil, error: String? = nil) {
        self.requestId = requestId
        self.tool = tool
        self.success = success
        self.result = result
        self.error = error
    }
}

