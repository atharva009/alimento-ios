//
//  GroceryView.swift
//  Alimento
//
//  Created on Phase 6
//

import SwiftUI
import SwiftData

struct GroceryView: View {
    var body: some View {
        GroceryListView()
    }
}

#Preview {
    GroceryView()
        .modelContainer(for: [
            UserProfile.self,
            InventoryItem.self,
            Dish.self,
            DishIngredient.self,
            PlannedMeal.self,
            GroceryList.self,
            GroceryItem.self,
            AiEventLog.self
        ])
}

