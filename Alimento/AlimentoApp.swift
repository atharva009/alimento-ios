//
//  AlimentoApp.swift
//  Alimento
//
//  Created on Phase 1
//

import SwiftUI
import SwiftData

@main
struct AlimentoApp: App {
    // SwiftData ModelContainer
    let container: ModelContainer
    
    init() {
        // Configure SwiftData schema
        let schema = Schema([
            UserProfile.self,
            InventoryItem.self,
            Dish.self,
            DishIngredient.self,
            PlannedMeal.self,
            GroceryList.self,
            GroceryItem.self,
            AiEventLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}

