//
//  ServicesContainer.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData
import SwiftUI
import Combine

/// Container for all services, providing dependency injection
@MainActor
final class ServicesContainer: ObservableObject {
    
    let inventoryService: InventoryService
    let dishLogService: DishLogService
    let plannerService: PlannerService
    let groceryService: GroceryService
    let aiService: AIService
    let seedDataService: SeedDataService
    
    init(modelContext: ModelContext) {
        // Initialize services in dependency order
        self.inventoryService = InventoryServiceImpl(modelContext: modelContext)
        self.dishLogService = DishLogServiceImpl(
            modelContext: modelContext,
            inventoryService: inventoryService
        )
        self.plannerService = PlannerServiceImpl(modelContext: modelContext)
            self.groceryService = GroceryServiceImpl(
                modelContext: modelContext,
                inventoryService: inventoryService,
                plannerService: plannerService
            )
            self.aiService = AIServiceImpl()
            self.seedDataService = SeedDataService(
                modelContext: modelContext,
                inventoryService: inventoryService,
                dishLogService: dishLogService,
                plannerService: plannerService
            )
    }
}
