//
//  InventoryViewModel.swift
//  Alimento
//
//  Created on Phase 3
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var selectedLocation: String = "all"
    
    private let inventoryService: InventoryService
    
    init(inventoryService: InventoryService) {
        self.inventoryService = inventoryService
    }
    
    var filteredItems: [InventoryItem] {
        if selectedLocation == "all" {
            return items
        }
        return items.filter { $0.location == selectedLocation }
    }
    
    var lowStockItems: [InventoryItem] {
        items.filter { $0.isLowStock }
    }
    
    var expiringSoonItems: [InventoryItem] {
        items.filter { $0.isExpiringSoon }
    }
    
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await inventoryService.fetchAllItems()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func deleteItem(_ item: InventoryItem) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await inventoryService.deleteItem(item)
            await loadItems()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func handleError(_ error: Error) {
        if let domainError = error as? DomainError {
            errorMessage = domainError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
}
