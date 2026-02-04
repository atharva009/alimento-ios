//
//  PlannerService.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

/// Protocol for meal planning operations
protocol PlannerService {
    // CRUD operations
    func createPlannedMeal(
        date: Date,
        mealType: String,
        title: String,
        dish: Dish?,
        ingredientNames: [String]
    ) async throws -> PlannedMeal
    
    func updatePlannedMeal(_ meal: PlannedMeal) async throws
    
    func deletePlannedMeal(_ meal: PlannedMeal) async throws
    
    func fetchPlannedMeals(for date: Date) async throws -> [PlannedMeal]
    
    func fetchPlannedMeals(in dateRange: ClosedRange<Date>) async throws -> [PlannedMeal]
    
    func fetchPlannedMeal(by id: PersistentIdentifier) async throws -> PlannedMeal?
}

