//
//  ErrorMapper.swift
//  Alimento
//
//  Created on Phase 10
//

import Foundation

/// Maps various error types to user-friendly messages
enum ErrorMapper {
    /// Maps any error to a user-friendly message
    static func userFriendlyMessage(for error: Error) -> String {
        if let domainError = error as? DomainError {
            return domainError.errorDescription ?? "An error occurred"
        } else if let aiError = error as? AIError {
            return aiError.errorDescription ?? "An AI error occurred"
        } else {
            // Handle SwiftData/CoreData and other NSError-backed errors
            let nsError = error as NSError
            if nsError.domain == "NSCocoaErrorDomain" {
                switch nsError.code {
                case 133020: // NSValidationMultipleErrorsError
                    return "Multiple validation errors occurred. Please check your input."
                case 133021: // NSValidationMissingMandatoryPropertyError
                    return "Required information is missing. Please fill in all required fields."
                case 133022: // NSValidationRelationshipLacksMinimumCountError
                    return "A required relationship is missing."
                case 133023: // NSValidationRelationshipExceedsMaximumCountError
                    return "Too many items in a relationship."
                case 133024: // NSValidationRelationshipDeniedDeleteError
                    return "Cannot delete this item because it is referenced by other items."
                case 1600: // NSPersistentStoreSaveError
                    return "Failed to save changes. Please try again."
                default:
                    return "Database error: \(nsError.localizedDescription)"
                }
            }
            return nsError.localizedDescription
        }
    }
    
    /// Determines if an error is recoverable (user can retry)
    static func isRecoverable(_ error: Error) -> Bool {
        if let aiError = error as? AIError {
            switch aiError {
            case .networkFailure, .rateLimited, .malformedJSON, .decodingFailure:
                return true
            case .missingApiKey, .modelRefused, .invalidRequest:
                return false
            }
        }
        
        if let domainError = error as? DomainError {
            switch domainError {
            case .persistenceError:
                return true
            default:
                return false
            }
        }
        
        // Network errors are generally recoverable
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }
}

