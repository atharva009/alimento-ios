//
//  InventoryService.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

/// Protocol for inventory management operations
protocol InventoryService {
    // CRUD operations
    func createItem(
        name: String,
        category: String,
        quantity: Double,
        unit: String,
        location: String,
        purchaseDate: Date,
        expiryDate: Date?,
        lowStockThreshold: Double
    ) async throws -> InventoryItem
    
    func updateItem(_ item: InventoryItem) async throws
    
    func deleteItem(_ item: InventoryItem) async throws
    
    func fetchAllItems() async throws -> [InventoryItem]
    
    func fetchItems(by location: String) async throws -> [InventoryItem]
    
    func fetchLowStockItems() async throws -> [InventoryItem]
    
    func fetchExpiringSoonItems(daysAhead: Int) async throws -> [InventoryItem]
    
    // Quantity operations
    func updateQuantity(_ item: InventoryItem, delta: Double) async throws
    
    func consumeItem(_ item: InventoryItem, amount: Double, unit: String) async throws
}

