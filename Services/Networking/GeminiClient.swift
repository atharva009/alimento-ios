//
//  GeminiClient.swift
//  Alimento
//
//  Created on Phase 7
//
//  Calls the Alimento backend proxy (API key stays server-side).
//

import Foundation

final class GeminiClient {
    private let baseURL: String
    private let session: URLSession
    private let timeout: TimeInterval = 30.0

    init(backendBaseURL: String) {
        let url = backendBaseURL.trimmingCharacters(in: .whitespaces)
        self.baseURL = url.hasSuffix("/") ? String(url.dropLast()) : url

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2

        self.session = URLSession(configuration: configuration)
    }

    func generateContent(
        prompt: String,
        systemInstruction: String? = nil
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw AIError.invalidRequest(message: "Invalid backend URL")
        }

        var requestBody: [String: Any] = ["prompt": prompt]
        if let sys = systemInstruction {
            requestBody["systemInstruction"] = sys
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIError.invalidRequest(message: "Failed to encode request: \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.networkFailure(message: "Invalid response type")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    throw AIError.rateLimited
                }

                let errorBody = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                let errorMessage = errorBody ?? String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIError.networkFailure(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String else {
                throw AIError.malformedJSON(message: "Response missing text content")
            }

            return text
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkFailure(message: error.localizedDescription)
        }
    }

    func cancel() {
        session.invalidateAndCancel()
    }
}
