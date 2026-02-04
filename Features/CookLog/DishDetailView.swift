//
//  DishDetailView.swift
//  Alimento
//
//  Created on Phase 4
//

import SwiftUI
import SwiftData

struct DishDetailView: View {
    let dish: Dish
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: dish.name)
                LabeledContent("Servings", value: "\(dish.servings)")
                LabeledContent("Date Cooked", value: dish.dateCooked, format: .dateTime)
            }
            
            if let steps = dish.steps, !steps.isEmpty {
                Section("Steps") {
                    Text(steps)
                }
            }
            
            if let ingredients = dish.ingredients, !ingredients.isEmpty {
                Section("Ingredients") {
                    ForEach(ingredients, id: \.persistentModelID) { ingredient in
                        HStack {
                            Text(ingredient.displayName)
                            Spacer()
                            Text("\(String(format: "%.2f", ingredient.amountUsed)) \(ingredient.unit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(dish.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DishDetailView(dish: Dish(name: "Pasta", servings: 4))
    }
    .modelContainer(for: [Dish.self, DishIngredient.self])
}
