//
//  AddToInventoryView.swift
//  Alimento
//
//  Created on Phase 6
//

import SwiftUI
import SwiftData

struct AddToInventoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroceryViewModel
    
    let item: GroceryItem
    
    @State private var selectedLocation: String = "pantry"
    
    private let locations = ["pantry", "fridge", "freezer"]
    
    var canAddToInventory: Bool {
        item.quantity > 0 && !item.unit.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    HStack {
                        Text("Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.name)
                            .font(.headline)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Item name: \(item.name)")
                    
                    HStack {
                        Text("Quantity")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(String(format: "%.2f", item.quantity)) \(item.unit)")
                            .font(.headline)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Quantity: \(String(format: "%.2f", item.quantity)) \(item.unit)")
                }
                
                Section("Inventory Location") {
                    Picker("Location", selection: $selectedLocation) {
                        ForEach(locations, id: \.self) { location in
                            Text(location.capitalized).tag(location)
                        }
                    }
                    .accessibilityLabel("Storage location")
                }
                
                if !canAddToInventory {
                    Section {
                        Text("This item needs a quantity and unit before it can be added to inventory.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Warning: This item needs a quantity and unit before it can be added to inventory")
                    }
                }
            }
            .navigationTitle("Add to Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addToInventory()
                    }
                    .disabled(!canAddToInventory || viewModel.isLoading)
                }
            }
        }
    }
    
    private func addToInventory() {
        Task {
            let success = await viewModel.addPurchasedToInventory(item, location: selectedLocation)
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    // Preview requires full app context
    Text("AddToInventoryView Preview")
        .modelContainer(for: [GroceryItem.self, InventoryItem.self])
}
