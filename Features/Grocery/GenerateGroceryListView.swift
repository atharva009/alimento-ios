//
//  GenerateGroceryListView.swift
//  Alimento
//
//  Created on Phase 6
//

import SwiftUI
import SwiftData

struct GenerateGroceryListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroceryViewModel
    
    @State private var daysAhead: Int = 7
    @State private var includePlannedMeals: Bool = true
    @State private var includeLowStock: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Generation Options") {
                    Stepper("Days Ahead: \(daysAhead)", value: $daysAhead, in: 1...14)
                        .accessibilityLabel("Days ahead: \(daysAhead)")
                    
                    Toggle("Include Planned Meals", isOn: $includePlannedMeals)
                        .accessibilityLabel("Include planned meals")
                        .accessibilityHint("Generate items from meals planned in the selected date range")
                    
                    Toggle("Include Low Stock Items", isOn: $includeLowStock)
                        .accessibilityLabel("Include low stock items")
                        .accessibilityHint("Generate items for inventory items that are low on stock")
                }
                
                Section {
                    Text("This will generate a grocery list based on:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if includePlannedMeals {
                        Label("Missing ingredients from planned meals", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if includeLowStock {
                        Label("Items that are low in stock", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !includePlannedMeals && !includeLowStock {
                        Text("Select at least one option to generate a list")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } footer: {
                    Text("Only meals linked to dishes will generate ingredient-based items. Custom title-only meals are skipped.")
                }
            }
            .navigationTitle("Generate List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        generateList()
                    }
                    .disabled((!includePlannedMeals && !includeLowStock) || viewModel.isLoading)
                }
            }
        }
    }
    
    private func generateList() {
        Task {
            let success = await viewModel.generateList(
                daysAhead: daysAhead,
                includePlannedMeals: includePlannedMeals,
                includeLowStock: includeLowStock
            )
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    // Preview requires full app context
    Text("GenerateGroceryListView Preview")
        .modelContainer(for: [GroceryList.self, GroceryItem.self])
}
