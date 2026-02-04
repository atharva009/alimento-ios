//
//  PreviewServices.swift
//  Alimento
//
//  Shared preview helper: in-memory ModelContainer + ServicesContainer for SwiftUI previews.
//

import SwiftUI
import SwiftData

enum PreviewServices {
    private static let schema = Schema([
        UserProfile.self,
        InventoryItem.self,
        Dish.self,
        DishIngredient.self,
        PlannedMeal.self,
        GroceryList.self,
        GroceryItem.self,
        AiEventLog.self
    ])
    
    /// In-memory container for previews. Use with .modelContainer(for: schema types) or this helper.
    static func inMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    /// Returns in-memory ModelContainer and ServicesContainer for previews. Use both in the preview:
    /// `View().modelContainer(c).environmentObject(services)` where `(c, services) = PreviewServices.previewContainer()`.
    @MainActor
    static func previewContainer() -> (ModelContainer, ServicesContainer) {
        let modelContainer = try! inMemoryContainer()
        let services = ServicesContainer(modelContext: modelContainer.mainContext)
        return (modelContainer, services)
    }
    
    /// Convenience for previews that only need ServicesContainer; still requires .modelContainer(...) for @Query.
    @MainActor
    static func container() -> ServicesContainer {
        previewContainer().1
    }
}
