//
//  AppTheme.swift
//  Alimento
//
//  Central design tokens for colors, typography, and spacing.
//

import SwiftUI

enum AppTheme {

    // MARK: - Brand & Accent

    /// Primary accent (buttons, links, selected tab, key actions) — modern teal
    static let accent = Color(red: 0.06, green: 0.58, blue: 0.55)
    static let accentSecondary = Color(red: 0.12, green: 0.68, blue: 0.65)

    /// Highlight for today/active states — soft teal tint
    static let highlight = Color(red: 0.90, green: 0.97, blue: 0.96)

    // MARK: - Surfaces

    /// Main screen background — soft tint so the app isn't pure white
    static let screenBackground = Color(red: 0.94, green: 0.96, blue: 0.98)

    /// Card and elevated content — white so cards pop on screen background
    static let cardBackground = Color(red: 1.0, green: 1.0, blue: 1.0)

    /// Elevated surface (e.g. list rows on cards)
    static let surface = Color(.systemBackground)

    /// Navigation bar / toolbar — subtle tint
    static let barBackground = Color(red: 0.98, green: 0.99, blue: 1.0)

    /// Subtle separator / secondary surface
    static let surfaceSecondary = Color(red: 0.92, green: 0.94, blue: 0.96)

    // MARK: - Layout & style

    static let cardCornerRadius: CGFloat = 14
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2

    // MARK: - Semantic (status / meaning)

    static let success = Color(red: 0.18, green: 0.70, blue: 0.52)
    static let warning = Color(red: 0.98, green: 0.65, blue: 0.22)
    static let danger = Color(red: 0.91, green: 0.27, blue: 0.33)
    static let info = Color(red: 0.25, green: 0.55, blue: 0.88)

    // MARK: - Feature accents (for icons/cards)

    static let inventory = Color(red: 0.06, green: 0.58, blue: 0.55)
    static let planner = success
    static let grocery = info
    static let cookLog = Color(red: 0.56, green: 0.40, blue: 0.78)
    static let ai = Color(red: 0.45, green: 0.38, blue: 0.82)
}

// MARK: - View extensions for theme

extension View {
    /// Card-style background with elevation
    func themedCardBackground() -> some View {
        background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .shadow(
                color: .black.opacity(0.06),
                radius: AppTheme.cardShadowRadius,
                x: 0,
                y: AppTheme.cardShadowY
            )
    }

    /// Standard card container: background + corner radius + light shadow
    func themedCard() -> some View {
        self
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .shadow(
                color: .black.opacity(0.06),
                radius: AppTheme.cardShadowRadius,
                x: 0,
                y: AppTheme.cardShadowY
            )
    }
}
