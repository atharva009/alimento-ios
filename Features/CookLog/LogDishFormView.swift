//
//  LogDishFormView.swift
//  Alimento
//
//  Created on Phase 4
//

import SwiftUI
import SwiftData

struct LogDishFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var services: ServicesContainer
    @Query private var inventoryItems: [InventoryItem]
    
    @State private var name: String = ""
    @State private var servings: String = "4"
    @State private var dateCooked: Date = Date()
    @State private var steps: String = ""
    @State private var selectedIngredients: [IngredientSelection] = []
    @State private var showingAddIngredient = false
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dish Details") {
                    TextField("Dish Name", text: $name)
                        .accessibilityLabel("Dish name")
                    
                    TextField("Servings", text: $servings)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Number of servings")
                    
                    DatePicker("Date Cooked", selection: $dateCooked, displayedComponents: .date)
                }
                
                Section("Ingredients") {
                    ForEach(selectedIngredients.indices, id: \.self) { index in
                        HStack {
                            Text(selectedIngredients[index].name)
                            Spacer()
                            Text("\(String(format: "%.2f", selectedIngredients[index].amount)) \(selectedIngredients[index].unit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indices in
                        selectedIngredients.remove(atOffsets: indices)
                    }
                    
                    Button("Add Ingredient") {
                        showingAddIngredient = true
                    }
                }
                
                Section("Steps (Optional)") {
                    TextEditor(text: $steps)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDish()
                    }
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientView(ingredients: $selectedIngredients, inventoryItems: inventoryItems)
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func saveDish() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Dish name cannot be empty"
            showingValidationError = true
            return
        }
        
        guard let servingsValue = Int(servings), servingsValue > 0 else {
            validationMessage = "Servings must be a positive number"
            showingValidationError = true
            return
        }
        
        guard !selectedIngredients.isEmpty else {
            validationMessage = "At least one ingredient is required"
            showingValidationError = true
            return
        }
        
        Task {
            do {
                let ingredients = selectedIngredients.map { sel in
                    (inventoryItem: sel.inventoryItem, name: sel.inventoryItem?.name ?? sel.name, amount: sel.amount, unit: sel.unit)
                }
                
                _ = try await services.dishLogService.logDish(
                    name: name,
                    servings: servingsValue,
                    dateCooked: dateCooked,
                    steps: steps.isEmpty ? nil : steps,
                    ingredients: ingredients
                )
                dismiss()
            } catch {
                validationMessage = error.localizedDescription
                showingValidationError = true
            }
        }
    }
}

struct IngredientSelection {
    let inventoryItem: InventoryItem?
    let name: String
    let amount: Double
    let unit: String
}

struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var ingredients: [IngredientSelection]
    let inventoryItems: [InventoryItem]
    
    @State private var selectedItem: InventoryItem?
    @State private var customName: String = ""
    @State private var amount: String = "1"
    @State private var unit: String = "pieces"
    @State private var useInventoryItem: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Use Inventory Item", isOn: $useInventoryItem)
                
                if useInventoryItem {
                    Picker("Item", selection: $selectedItem) {
                        Text("Select Item").tag(nil as InventoryItem?)
                        ForEach(inventoryItems) { item in
                            Text(item.name).tag(item as InventoryItem?)
                        }
                    }
                } else {
                    TextField("Ingredient Name", text: $customName)
                }
                
                HStack {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(["pieces", "g", "kg", "oz", "lb", "ml", "L"], id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addIngredient()
                    }
                }
            }
        }
    }
    
    private func addIngredient() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        if useInventoryItem, let item = selectedItem {
            ingredients.append(IngredientSelection(
                inventoryItem: item,
                name: item.name,
                amount: amountValue,
                unit: unit
            ))
        } else if !customName.isEmpty {
            ingredients.append(IngredientSelection(
                inventoryItem: nil,
                name: customName,
                amount: amountValue,
                unit: unit
            ))
        }
        
        dismiss()
    }
}

#Preview {
    LogDishFormView()
        .modelContainer(for: [Dish.self, InventoryItem.self])
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: Dish.self))))
}
