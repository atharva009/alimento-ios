//
//  GroceryService.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

/// Protocol for grocery list operations
protocol GroceryService {
    // List operations
    func generateGroceryList(daysAhead: Int) async throws -> GroceryList
    
    func createGroceryList(daysAhead: Int) async throws -> GroceryList
    
    func fetchActiveGroceryList() async throws -> GroceryList?
    
    func fetchAllGroceryLists() async throws -> [GroceryList]
    
    // Item operations
    func addItemToList(
        _ list: GroceryList,
        name: String,
        quantity: Double,
        unit: String,
        reason: String,
        priority: Int
    ) async throws -> GroceryItem
    
    func updateItem(_ item: GroceryItem) async throws
    
    func deleteItem(_ item: GroceryItem) async throws
    
    func markItemPurchased(_ item: GroceryItem, isPurchased: Bool) async throws
    
    func addPurchasedItemToInventory(_ item: GroceryItem) async throws -> InventoryItem
}

