//
//  ConsumeItemView.swift
//  Alimento
//
//  Created on Phase 3
//

import SwiftUI
import SwiftData

struct ConsumeItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var services: ServicesContainer
    
    let item: InventoryItem
    
    @State private var amount: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    Text(item.name)
                        .font(.headline)
                    Text("Available: \(String(format: "%.2f", item.quantity)) \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Consume") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Amount to consume")
                    
                    Text("Unit: \(item.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Consume Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Consume") {
                        consumeItem()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func consumeItem() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }
        
        Task {
            do {
                try await services.inventoryService.consumeItem(item, amount: amountValue, unit: item.unit)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    ConsumeItemView(item: InventoryItem(name: "Tomatoes", category: "Produce", quantity: 2.0, unit: "kg", location: "fridge"))
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: InventoryItem.self))))
}
