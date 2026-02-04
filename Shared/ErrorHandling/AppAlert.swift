//
//  AppAlert.swift
//  Alimento
//
//  Created on Phase 10
//

import Foundation
import SwiftUI

/// Centralized error presentation model for user-facing alerts
struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryAction: AlertAction?
    let secondaryAction: AlertAction?
    
    struct AlertAction {
        let title: String
        let role: ButtonRole?
        let action: (() -> Void)?
        
        init(title: String, role: ButtonRole? = nil, action: (() -> Void)? = nil) {
            self.title = title
            self.role = role
            self.action = action
        }
    }
    
    init(title: String, message: String, primaryAction: AlertAction? = nil, secondaryAction: AlertAction? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    /// Creates an alert from any Error
    static func from(_ error: Error) -> AppAlert {
        if let domainError = error as? DomainError {
            return AppAlert(
                title: "Error",
                message: domainError.errorDescription ?? "An error occurred"
            )
        } else if let aiError = error as? AIError {
            return AppAlert(
                title: "AI Error",
                message: aiError.errorDescription ?? "An AI error occurred"
            )
        } else {
            return AppAlert(
                title: "Error",
                message: error.localizedDescription
            )
        }
    }
    
    /// Creates an alert with retry action
    static func withRetry(title: String, message: String, retryAction: @escaping () -> Void) -> AppAlert {
        AppAlert(
            title: title,
            message: message,
            primaryAction: AlertAction(title: "Retry", action: retryAction),
            secondaryAction: AlertAction(title: "OK", role: .cancel)
        )
    }
}

/// View modifier for presenting AppAlert
struct AppAlertModifier: ViewModifier {
    @Binding var alert: AppAlert?
    
    func body(content: Content) -> some View {
        content
            .alert(alert?.title ?? "Error", isPresented: Binding(
                get: { alert != nil },
                set: { if !$0 { alert = nil } }
            )) {
                if let primary = alert?.primaryAction {
                    Button(primary.title, role: primary.role) {
                        primary.action?()
                    }
                }
                if let secondary = alert?.secondaryAction {
                    Button(secondary.title, role: secondary.role) {
                        secondary.action?()
                    }
                } else if alert?.primaryAction == nil {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                if let message = alert?.message {
                    Text(message)
                }
            }
    }
}

extension View {
    func appAlert(_ alert: Binding<AppAlert?>) -> some View {
        modifier(AppAlertModifier(alert: alert))
    }
}

