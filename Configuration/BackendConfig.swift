//
//  BackendConfig.swift
//  Alimento
//
//  Configuration for the AI backend proxy. The API key stays on the server.
//  Reads BackendBaseURL from Info.plist so you can change it per scheme/config without code edits.
//

import Foundation

enum BackendConfig {
    /// Base URL of the Alimento Gemini proxy. Read from Info.plist key `BackendBaseURL`, with fallback for local dev.
    /// - Set in Info.plist or xcconfig for your environment (Simulator: localhost, device: machine IP, production: deployed URL).
    static var baseURL: String? {
        (Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String)?
            .trimmingCharacters(in: .whitespaces)
            .nonEmpty
            ?? "http://localhost:3000"
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
