//
//  GrocerySuggestionsView.swift
//  Alimento
//
//  Created on Phase 7
//

import SwiftUI
import SwiftData

struct GrocerySuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: ServicesContainer
    @Query private var plannedMeals: [PlannedMeal]
    @Query private var inventoryItems: [InventoryItem]
    
    @State private var suggestions: [GroceryItemSuggestion] = []
    @State private var state = AISuggestionState()
    @State private var showingApplyConfirmation = false
    
    var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if state.isLoading {
                    ProgressView("Generating grocery list...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if suggestions.isEmpty && !state.isLoading {
                    ContentUnavailableView {
                        Label("No Suggestions", systemImage: "cart")
                    } description: {
                        Text("Tap Generate to get AI-powered grocery list suggestions")
                    } actions: {
                        Button("Generate") {
                            generateSuggestions()
                        }
                    }
                } else {
                    List {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, item in
                            GrocerySuggestionRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Grocery Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            generateSuggestions()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        if !suggestions.isEmpty {
                            Button {
                                showingApplyConfirmation = true
                            } label: {
                                Label("Apply to List", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .appAlert($state.alert)
            .alert("Apply to Grocery List", isPresented: $showingApplyConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Apply") {
                    applyToGroceryList()
                }
            } message: {
                Text("This will add \(suggestions.count) items to your active grocery list. Continue?")
            }
        }
    }
    
    private func generateSuggestions() {
        state.startLoading()
        Task {
            do {
                let results = try await services.aiService.generateGroceryList(
                    plannedMeals: plannedMeals,
                    currentInventory: inventoryItems,
                    lowStockItems: lowStockItems
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
    
    private func applyToGroceryList() {
        Task {
            do {
                var activeList = try await services.groceryService.fetchActiveGroceryList()
                if activeList == nil {
                    activeList = try await services.groceryService.createGroceryList(daysAhead: 7)
                }
                guard let list = activeList else {
                    throw DomainError.groceryListNotFound
                }
                for item in suggestions {
                    _ = try await services.groceryService.addItemToList(
                        list,
                        name: item.name,
                        quantity: item.quantity,
                        unit: item.unit,
                        reason: item.reason,
                        priority: item.priority
                    )
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    state.setError(error)
                }
            }
        }
    }
}

struct GrocerySuggestionRow: View {
    let item: GroceryItemSuggestion
    
    var reasonColor: Color {
        switch item.reason {
        case "missing": return .red
        case "low_stock": return .orange
        case "staple": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text("\(String(format: "%.2f", item.quantity)) \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item.reason.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(reasonColor.opacity(0.2))
                        .foregroundStyle(reasonColor)
                        .cornerRadius(4)
                }
            }
            Spacer()
            if item.priority == 1 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityLabel("High priority")
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return GrocerySuggestionsView()
        .modelContainer(modelContainer)
        .environmentObject(services)
}
