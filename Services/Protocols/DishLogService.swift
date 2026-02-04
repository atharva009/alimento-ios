//
//  DishLogService.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

/// Protocol for dish logging and history operations
protocol DishLogService {
    // CRUD operations
    func logDish(
        name: String,
        servings: Int,
        dateCooked: Date,
        steps: String?,
        ingredients: [(inventoryItem: InventoryItem?, name: String?, amount: Double, unit: String)]
    ) async throws -> Dish
    
    func updateDish(_ dish: Dish) async throws
    
    func deleteDish(_ dish: Dish) async throws
    
    func fetchAllDishes() async throws -> [Dish]
    
    func fetchDishes(in dateRange: ClosedRange<Date>) async throws -> [Dish]
    
    func fetchDish(by id: PersistentIdentifier) async throws -> Dish?
}

