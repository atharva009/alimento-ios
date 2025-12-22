//
//  ContentView.swift
//  Alimento
//
//  Created on Phase 1
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "cabinet.fill")
                }
                .tag(1)
            
            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
                .tag(2)
            
            GroceryView()
                .tabItem {
                    Label("Grocery", systemImage: "cart.fill")
                }
                .tag(3)
            
            AssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "message.fill")
                }
                .tag(4)
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
}

