//
//  GroceryItemEditorView.swift
//  Alimento
//
//  Created on Phase 6
//

import SwiftUI
import SwiftData

struct GroceryItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroceryViewModel
    
    let item: GroceryItem?
    
    @State private var name: String = ""
    @State private var quantity: String = "1"
    @State private var unit: String = "pieces"
    @State private var reason: String = "manual"
    @State private var priority: String = "medium"
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private let units = ["pieces", "g", "kg", "oz", "lb", "ml", "L"]
    private let priorities = ["high", "medium", "low"]
    private let reasons = ["manual", "missing", "low_stock", "staple"]
    
    var isEditMode: Bool {
        item != nil
    }
    
    var isReasonEditable: Bool {
        item?.reason == "manual" || item == nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (quantity.isEmpty || Double(quantity) != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .accessibilityLabel("Item name")
                        .autocorrectionDisabled()
                    
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Quantity")
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .accessibilityLabel("Unit")
                    }
                }
                
                Section("Options") {
                    if isReasonEditable {
                        Picker("Reason", selection: $reason) {
                            ForEach(reasons, id: \.self) { reason in
                                Text(reason.capitalized).tag(reason)
                            }
                        }
                        .accessibilityLabel("Reason")
                    } else {
                        HStack {
                            Text("Reason")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(reason.capitalized)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Reason: \(reason)")
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority.capitalized).tag(priority)
                        }
                    }
                    .accessibilityLabel("Priority")
                }
            }
            .navigationTitle(isEditMode ? "Edit Item" : "Add Item")
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
                    .disabled(!isValid || viewModel.isLoading)
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
    
    // MARK: - Private Methods
    
    private func loadItemData() {
        if let existingItem = item {
            name = existingItem.name
            quantity = existingItem.quantity > 0 ? String(format: "%.2f", existingItem.quantity) : ""
            unit = existingItem.unit
            reason = existingItem.reason
            priority = viewModel.intToPriority(existingItem.priority)
        } else {
            name = ""
            quantity = "1"
            unit = "pieces"
            reason = "manual"
            priority = "medium"
        }
    }
    
    private func saveItem() {
        // Validate name
        if let error = viewModel.validateName(name) {
            validationMessage = error
            showingValidationError = true
            return
        }
        
        // Validate quantity
        let quantityValue: Double?
        if quantity.isEmpty {
            quantityValue = nil
        } else if let qty = Double(quantity) {
            if qty <= 0 {
                validationMessage = "Quantity must be greater than zero"
                showingValidationError = true
                return
            }
            quantityValue = qty
        } else {
            validationMessage = "Invalid quantity"
            showingValidationError = true
            return
        }
        
        // Save
        Task {
            let success: Bool
            if let existingItem = item {
                success = await viewModel.updateItem(
                    existingItem,
                    name: name.trimmingCharacters(in: .whitespaces),
                    quantity: quantityValue,
                    unit: unit,
                    reason: reason,
                    priority: priority
                )
            } else {
                success = await viewModel.addItem(
                    name: name.trimmingCharacters(in: .whitespaces),
                    quantity: quantityValue,
                    unit: unit,
                    reason: reason,
                    priority: priority
                )
            }
            
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    // Preview requires full app context
    Text("GroceryItemEditorView Preview")
        .modelContainer(for: [GroceryItem.self, GroceryList.self])
}
