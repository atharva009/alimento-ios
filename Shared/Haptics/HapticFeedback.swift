//
//  HapticFeedback.swift
//  Alimento
//
//  Created on Phase 9
//

import UIKit

enum HapticFeedback {
    case success
    case warning
    case error
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    
    func play() {
        switch self {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}

