//
//  AddEditInventoryItemView.swift
//  Alimento
//
//  Created on Phase 3
//

import SwiftUI
import SwiftData

struct AddEditInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var services: ServicesContainer
    
    let item: InventoryItem?
    
    @State private var name: String = ""
    @State private var category: String = "Other"
    @State private var quantity: String = "1"
    @State private var unit: String = "pieces"
    @State private var location: String = "pantry"
    @State private var purchaseDate: Date = Date()
    @State private var expiryDate: Date? = nil
    @State private var hasExpiry: Bool = false
    @State private var lowStockThreshold: String = "0"
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private let categories = ["Produce", "Dairy", "Meat", "Grains", "Spices", "Other"]
    private let units = ["pieces", "g", "kg", "oz", "lb", "ml", "L"]
    private let locations = ["pantry", "fridge", "freezer"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Item name")
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Quantity")
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                    }
                    
                    Picker("Location", selection: $location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc.capitalized).tag(loc)
                        }
                    }
                }
                
                Section("Dates") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    Toggle("Has Expiry Date", isOn: $hasExpiry)
                    
                    if hasExpiry {
                        DatePicker("Expiry Date", selection: Binding(
                            get: { expiryDate ?? Date() },
                            set: { expiryDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section("Low Stock Alert") {
                    TextField("Threshold", text: $lowStockThreshold)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Low stock threshold")
                }
            }
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadItemData()
            }
        }
    }
    
    private func loadItemData() {
        if let existingItem = item {
            name = existingItem.name
            category = existingItem.category
            quantity = String(format: "%.2f", existingItem.quantity)
            unit = existingItem.unit
            location = existingItem.location
            purchaseDate = existingItem.purchaseDate
            expiryDate = existingItem.expiryDate
            hasExpiry = existingItem.expiryDate != nil
            lowStockThreshold = String(format: "%.2f", existingItem.lowStockThreshold)
        }
    }
    
    private func saveItem() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Item name cannot be empty"
            showingValidationError = true
            return
        }
        
        guard let qty = Double(quantity), qty >= 0 else {
            validationMessage = "Quantity must be a valid number"
            showingValidationError = true
            return
        }
        
        guard let threshold = Double(lowStockThreshold), threshold >= 0 else {
            validationMessage = "Low stock threshold must be a valid number"
            showingValidationError = true
            return
        }
        
        Task {
            do {
                if let existingItem = item {
                    existingItem.name = name
                    existingItem.category = category
                    existingItem.quantity = qty
                    existingItem.unit = unit
                    existingItem.location = location
                    existingItem.purchaseDate = purchaseDate
                    existingItem.expiryDate = hasExpiry ? expiryDate : nil
                    existingItem.lowStockThreshold = threshold
                    try await services.inventoryService.updateItem(existingItem)
                } else {
                    _ = try await services.inventoryService.createItem(
                        name: name,
                        category: category,
                        quantity: qty,
                        unit: unit,
                        location: location,
                        purchaseDate: purchaseDate,
                        expiryDate: hasExpiry ? expiryDate : nil,
                        lowStockThreshold: threshold
                    )
                }
                dismiss()
            } catch {
                validationMessage = error.localizedDescription
                showingValidationError = true
            }
        }
    }
}

#Preview {
    AddEditInventoryItemView(item: nil)
        .modelContainer(for: [InventoryItem.self])
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: InventoryItem.self))))
}

