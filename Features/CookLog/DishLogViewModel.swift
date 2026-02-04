//
//  DishLogViewModel.swift
//  Alimento
//
//  Created on Phase 4
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class DishLogViewModel: ObservableObject {
    @Published var dishes: [Dish] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let dishLogService: DishLogService
    
    init(dishLogService: DishLogService) {
        self.dishLogService = dishLogService
    }
    
    func loadDishes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dishes = try await dishLogService.fetchAllDishes()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func deleteDish(_ dish: Dish) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dishLogService.deleteDish(dish)
            await loadDishes()
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
