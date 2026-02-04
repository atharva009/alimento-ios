//
//  PlannedMealEditorView.swift
//  Alimento
//
//  Created on Phase 5
//

import SwiftUI
import SwiftData

struct PlannedMealEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: PlannerViewModel
    
    var initialDate: Date
    var initialMealType: String?
    var meal: PlannedMeal?
    
    @State private var selectedDate: Date
    @State private var selectedMealType: String
    @State private var sourceType: MealSourceType = .custom
    @State private var customTitle: String = ""
    @State private var selectedDish: Dish?
    @State private var showingDishPicker = false
    @State private var ingredientNames: [String] = []
    @State private var newIngredientName: String = ""
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    var isEditMode: Bool {
        meal != nil
    }
    
    var isValid: Bool {
        !selectedMealType.isEmpty &&
        (sourceType == .dish ? selectedDish != nil : !customTitle.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    var displayTitle: String {
        if sourceType == .dish, let dish = selectedDish {
            return dish.name
        }
        return customTitle
    }
    
    init(viewModel: PlannerViewModel, initialDate: Date, initialMealType: String?, meal: PlannedMeal?) {
        self.viewModel = viewModel
        self.initialDate = initialDate
        self.initialMealType = initialMealType
        self.meal = meal
        _selectedDate = State(initialValue: initialDate)
        _selectedMealType = State(initialValue: initialMealType ?? "breakfast")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Date and Meal Type
                Section("Meal Details") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .accessibilityLabel("Meal date")
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .accessibilityLabel("Meal type")
                }
                
                // Source Type
                Section("Source") {
                    Picker("Source", selection: $sourceType) {
                        Text("Link Dish").tag(MealSourceType.dish)
                        Text("Custom Title").tag(MealSourceType.custom)
                    }
                    .accessibilityLabel("Meal source")
                    
                    if sourceType == .dish {
                        Button {
                            showingDishPicker = true
                        } label: {
                            HStack {
                                Text("Select Dish")
                                Spacer()
                                if let dish = selectedDish {
                                    Text(dish.name)
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    } else {
                        TextField("Meal Title", text: $customTitle)
                            .accessibilityLabel("Meal title")
                    }
                }
                
                // Ingredient Names (optional, for custom meals)
                if sourceType == .custom {
                    Section("Ingredient Names (Optional)") {
                        ForEach(ingredientNames, id: \.self) { name in
                            Text(name)
                        }
                        .onDelete { indices in
                            ingredientNames.remove(atOffsets: indices)
                        }
                        
                        HStack {
                            TextField("Add ingredient", text: $newIngredientName)
                            Button("Add") {
                                if !newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    ingredientNames.append(newIngredientName.trimmingCharacters(in: .whitespaces))
                                    newIngredientName = ""
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Meal" : "Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(!isValid || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingDishPicker) {
                DishPickerView(selectedDish: $selectedDish)
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadMealData()
            }
        }
    }
    
    private func loadMealData() {
        if let existingMeal = meal {
            selectedDate = existingMeal.date
            selectedMealType = existingMeal.mealType
            selectedDish = existingMeal.dish
            customTitle = existingMeal.title
            ingredientNames = existingMeal.ingredientNames
            sourceType = existingMeal.dish != nil ? .dish : .custom
        } else {
            customTitle = ""
            selectedDish = nil
            ingredientNames = []
        }
    }
    
    private func saveMeal() {
        let title = sourceType == .dish ? (selectedDish?.name ?? "") : customTitle.trimmingCharacters(in: .whitespaces)
        
        guard !title.isEmpty else {
            validationMessage = "Meal title cannot be empty"
            showingValidationError = true
            return
        }
        
        Task {
            if let existingMeal = meal {
                await viewModel.updatePlannedMeal(existingMeal, date: selectedDate, mealType: selectedMealType, title: title, dish: selectedDish)
            } else {
                await viewModel.addPlannedMeal(date: selectedDate, mealType: selectedMealType, title: title, dish: selectedDish)
            }
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                validationMessage = viewModel.errorMessage ?? "Failed to save meal"
                showingValidationError = true
            }
        }
    }
}

enum MealSourceType {
    case dish
    case custom
}

#Preview {
    // Preview requires full app context
    Text("PlannedMealEditorView Preview")
        .modelContainer(for: [PlannedMeal.self, Dish.self])
}
