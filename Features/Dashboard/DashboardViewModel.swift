//
//  DashboardViewModel.swift
//  Alimento
//
//  Created on Phase 9
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var lowStockCount: Int = 0
    @Published var expiringSoonCount: Int = 0
    @Published var todayMealsCount: Int = 0
    @Published var groceryRemainingCount: Int = 0
    @Published var todaysMeals: [PlannedMeal] = []
    @Published var isLoading = false
    
    var modelContext: ModelContext
    private let inventoryService: InventoryService
    private let plannerService: PlannerService
    private let groceryService: GroceryService
    
    init(
        modelContext: ModelContext,
        inventoryService: InventoryService,
        plannerService: PlannerService,
        groceryService: GroceryService
    ) {
        self.modelContext = modelContext
        self.inventoryService = inventoryService
        self.plannerService = plannerService
        self.groceryService = groceryService
    }
    
    func refresh() async {
        isLoading = true
        
        // Fetch low stock items
        do {
            let lowStockItems = try await inventoryService.fetchLowStockItems()
            lowStockCount = lowStockItems.count
        } catch {
            // Silently fail for dashboard - errors are non-critical here
            lowStockCount = 0
        }
        
        // Fetch expiring soon items (within 7 days)
        do {
            let expiringItems = try await inventoryService.fetchExpiringSoonItems(daysAhead: 7)
            expiringSoonCount = expiringItems.count
        } catch {
            // Silently fail for dashboard - errors are non-critical here
            expiringSoonCount = 0
        }
        
        // Fetch today's meals
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        do {
            let meals = try await plannerService.fetchPlannedMeals(in: today...tomorrow)
            todayMealsCount = meals.count
            // Pre-compute sorted meals to avoid sorting in View body
            let mealTypeOrder = ["breakfast", "lunch", "dinner", "snack"]
            todaysMeals = meals.sorted { meal1, meal2 in
                let index1 = mealTypeOrder.firstIndex(of: meal1.mealType) ?? 999
                let index2 = mealTypeOrder.firstIndex(of: meal2.mealType) ?? 999
                return index1 < index2
            }
        } catch {
            // Silently fail for dashboard - errors are non-critical here
            todayMealsCount = 0
            todaysMeals = []
        }
        
        // Fetch grocery items
        do {
            let activeList = try await groceryService.fetchActiveGroceryList()
            if let list = activeList {
                let items = list.items ?? []
                groceryRemainingCount = items.filter { !$0.isPurchased }.count
            } else {
                groceryRemainingCount = 0
            }
        } catch {
            // Silently fail for dashboard - errors are non-critical here
            groceryRemainingCount = 0
        }
        
        isLoading = false
    }
    
    func todaysMealsByType(_ mealType: String) -> [PlannedMeal] {
        todaysMeals.filter { $0.mealType == mealType }
    }
}

