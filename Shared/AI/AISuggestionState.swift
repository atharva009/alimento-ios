//
//  AISuggestionState.swift
//  Alimento
//
//  Shared loading and error state for AI suggestion views (meal, grocery, weekly plan).
//

import SwiftUI

/// Holds loading and error state for AI suggestion flows. Use with `AppAlert` for consistent error UX.
struct AISuggestionState {
    var isLoading = false
    var alert: AppAlert?
    
    mutating func startLoading() {
        isLoading = true
        alert = nil
    }
    
    mutating func finishLoading() {
        isLoading = false
    }
    
    mutating func setError(_ error: Error, retryAction: (() -> Void)? = nil) {
        isLoading = false
        let message = ErrorMapper.userFriendlyMessage(for: error)
        if ErrorMapper.isRecoverable(error), let retry = retryAction {
            alert = AppAlert.withRetry(title: "Error", message: message, retryAction: retry)
        } else {
            alert = AppAlert.from(error)
        }
    }
    
    mutating func clearError() {
        alert = nil
    }
}
