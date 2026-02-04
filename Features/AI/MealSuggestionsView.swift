//
//  MealSuggestionsView.swift
//  Alimento
//
//  Created on Phase 7
//

import SwiftUI
import SwiftData

struct MealSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: ServicesContainer
    @Query private var inventoryItems: [InventoryItem]
    @Query private var userProfiles: [UserProfile]
    
    @State private var suggestions: [MealSuggestion] = []
    @State private var state = AISuggestionState()
    
    var body: some View {
        NavigationStack {
            Group {
                if state.isLoading {
                    ProgressView("Generating meal suggestions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if suggestions.isEmpty && !state.isLoading {
                    ContentUnavailableView {
                        Label("No Suggestions", systemImage: "fork.knife")
                    } description: {
                        Text("Tap Generate to get AI-powered meal suggestions based on your inventory")
                    } actions: {
                        Button("Generate") {
                            generateSuggestions()
                        }
                    }
                } else {
                    List {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            MealSuggestionCard(suggestion: suggestion)
                        }
                    }
                }
            }
            .navigationTitle("Meal Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate") {
                        generateSuggestions()
                    }
                    .disabled(state.isLoading)
                }
            }
            .appAlert($state.alert)
        }
    }
    
    private func generateSuggestions() {
        state.startLoading()
        let profile = userProfiles.first ?? UserProfile()
        
        Task {
            do {
                let results = try await services.aiService.suggestMealsFromInventory(
                    inventoryItems: inventoryItems,
                    preferences: profile,
                    timeConstraint: nil
                )
                await MainActor.run {
                    suggestions = results
                    state.finishLoading()
                }
            } catch {
                await MainActor.run {
                    state.setError(error, retryAction: { generateSuggestions() })
                }
            }
        }
    }
}

struct MealSuggestionCard: View {
    let suggestion: MealSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.headline)
                
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("\(suggestion.cookTimeMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(suggestion.estimatedMacros.calories) cal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !suggestion.requiredIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Required Ingredients:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(suggestion.requiredIngredients, id: \.name) { ingredient in
                        Text("• \(ingredient.name): \(String(format: "%.2f", ingredient.quantity)) \(ingredient.unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !suggestion.missingIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missing Ingredients:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    
                    ForEach(suggestion.missingIngredients, id: \.name) { ingredient in
                        Text("• \(ingredient.name): \(String(format: "%.2f", ingredient.quantity)) \(ingredient.unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !suggestion.steps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(suggestion.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text("Nutritional information is an estimate only")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return MealSuggestionsView()
        .modelContainer(modelContainer)
        .environmentObject(services)
}
