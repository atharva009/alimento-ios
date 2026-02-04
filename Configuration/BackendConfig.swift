//
//  BackendConfig.swift
//  Alimento
//
//  Configuration for the AI backend proxy. The API key stays on the server.
//

import Foundation

enum BackendConfig {
    /// Base URL of the Alimento Gemini proxy (e.g. http://localhost:3000)
    /// - For Simulator: use http://localhost:3000
    /// - For physical device: use your machine's IP, e.g. http://192.168.1.100:3000
    /// - For production: use your deployed backend URL
    static let baseURL: String? = "http://localhost:3000"
}
