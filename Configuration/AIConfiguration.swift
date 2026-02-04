//
//  AIConfiguration.swift
//  Alimento
//
//  Created on Phase 7
//

import Foundation

enum AIMode {
    case mock
    case live
}

final class AIConfiguration {
    static let shared = AIConfiguration()
    
    private let backendBaseURL: String?
    private let _mode: AIMode
    
    var mode: AIMode {
        _mode
    }
    
    /// True when backend proxy is configured (live AI mode)
    var hasAPIKey: Bool {
        guard let url = backendBaseURL else { return false }
        return !url.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private init() {
        let url = BackendConfig.baseURL?.trimmingCharacters(in: .whitespaces)
        self.backendBaseURL = (url != nil && !url!.isEmpty) ? url : nil
        self._mode = backendBaseURL != nil ? .live : .mock
    }
    
    func getBackendBaseURL() throws -> String {
        guard let url = backendBaseURL, !url.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIError.missingApiKey
        }
        return url.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/$", with: "", options: .regularExpression)
    }
}

