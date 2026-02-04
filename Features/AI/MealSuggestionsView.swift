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
    @Environment(\.modelContext) private var modelContext
    @Query private var inventoryItems: [InventoryItem]
    @Query private var userProfiles: [UserProfile]
    
    @State private var suggestions: [MealSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private var aiService: AIService {
        AIServiceImpl()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Generating meal suggestions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if suggestions.isEmpty && !isLoading {
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
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func generateSuggestions() {
        isLoading = true
        errorMessage = nil
        
        let profile = userProfiles.first ?? UserProfile()
        
        Task {
            do {
                let results = try await aiService.suggestMealsFromInventory(
                    inventoryItems: inventoryItems,
                    preferences: profile,
                    timeConstraint: nil
                )
                await MainActor.run {
                    suggestions = results
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
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
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    MealSuggestionsView()
        .modelContainer(for: [InventoryItem.self, UserProfile.self])
}

