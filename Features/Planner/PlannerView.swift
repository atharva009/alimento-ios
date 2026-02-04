//
//  PlannerView.swift
//  Alimento
//
//  Created on Phase 5
//

import SwiftUI
import SwiftData

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var services: ServicesContainer
    
    var body: some View {
        PlannerWeekView()
            .environmentObject(PlannerViewModel(
                plannerService: services.plannerService,
                dishLogService: services.dishLogService
            ))
    }
}

#Preview {
    PlannerView()
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
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: PlannedMeal.self))))
}
