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
    @Environment(\.modelContext) private var modelContext
    @Query private var plannedMeals: [PlannedMeal]
    @Query private var inventoryItems: [InventoryItem]
    
    @State private var suggestions: [GroceryItemSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingApplyConfirmation = false
    
    private var aiService: AIService {
        AIServiceImpl()
    }
    
    private var groceryService: GroceryService {
        let plannerService = PlannerServiceImpl(modelContext: modelContext)
        return GroceryServiceImpl(
            modelContext: modelContext,
            inventoryService: InventoryServiceImpl(modelContext: modelContext),
            plannerService: plannerService
        )
    }
    
    var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Generating grocery list...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if suggestions.isEmpty && !isLoading {
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
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
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await aiService.generateGroceryList(
                    plannedMeals: plannedMeals,
                    currentInventory: inventoryItems,
                    lowStockItems: lowStockItems
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
    
    private func applyToGroceryList() {
        Task {
            do {
                // Get or create active list
                var activeList = try await groceryService.fetchActiveGroceryList()
                if activeList == nil {
                    activeList = try await groceryService.createGroceryList(daysAhead: 7)
                }
                
                guard let list = activeList else {
                    throw DomainError.groceryListNotFound
                }
                
                // Add items
                for item in suggestions {
                    _ = try await groceryService.addItemToList(
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
                    errorMessage = error.localizedDescription
                    showingError = true
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
    GrocerySuggestionsView()
        .modelContainer(for: [PlannedMeal.self, InventoryItem.self, GroceryList.self])
}

