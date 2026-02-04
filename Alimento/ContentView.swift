//
//  ContentView.swift
//  Alimento
//
//  Created on Phase 1
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "cabinet.fill")
                }
            
            CookLogView()
                .tabItem {
                    Label("Cook Log", systemImage: "fork.knife")
                }
            
            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
            
            GroceryView()
                .tabItem {
                    Label("Grocery", systemImage: "cart.fill")
                }
        }
    }
}

#Preview {
    ContentView()
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
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: InventoryItem.self))))
}

