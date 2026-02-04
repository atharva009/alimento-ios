//
//  AlimentoApp.swift
//  Alimento
//
//  Created on Phase 1, Enhanced in Phase 9
//

import SwiftUI
import SwiftData
import TipKit

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
        
        // Configure TipKit (iOS 17+)
        if #available(iOS 17.0, *) {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(ServicesContainer(modelContext: container.mainContext))
                .task {
                    // Seed data on first launch
                    await seedDataIfNeeded()
                }
        }
    }
    
    @MainActor
    private func seedDataIfNeeded() async {
        let context = container.mainContext
        let services = ServicesContainer(modelContext: context)
        
        do {
            _ = try await services.seedDataService.seedIfNeeded()
        } catch {
            // Silently fail - seed data is optional for demo
            #if DEBUG
            // Only log in debug builds
            #endif
        }
    }
}

