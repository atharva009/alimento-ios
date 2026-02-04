//
//  PlannerServiceImpl.swift
//  Alimento
//
//  Created on Phase 2
//

import Foundation
import SwiftData

@MainActor
final class PlannerServiceImpl: PlannerService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createPlannedMeal(
        date: Date,
        mealType: String,
        title: String,
        dish: Dish?,
        ingredientNames: [String]
    ) async throws -> PlannedMeal {
        let validMealTypes = ["breakfast", "lunch", "dinner", "snack"]
        guard validMealTypes.contains(mealType.lowercased()) else {
            throw DomainError.invalidMealType(mealType: mealType)
        }
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DomainError.validationFailed(message: "Meal title cannot be empty")
        }
        
        let meal = PlannedMeal(
            date: date,
            mealType: mealType.lowercased(),
            title: title,
            dish: dish,
            ingredientNames: ingredientNames
        )
        
        modelContext.insert(meal)
        
        do {
            try modelContext.save()
            return meal
        } catch {
            throw DomainError.persistenceError(message: "Failed to create planned meal: \(error.localizedDescription)")
        }
    }
    
    func updatePlannedMeal(_ meal: PlannedMeal) async throws {
        let validMealTypes = ["breakfast", "lunch", "dinner", "snack"]
        guard validMealTypes.contains(meal.mealType.lowercased()) else {
            throw DomainError.invalidMealType(mealType: meal.mealType)
        }
        
        guard !meal.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DomainError.validationFailed(message: "Meal title cannot be empty")
        }
        
        meal.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to update planned meal: \(error.localizedDescription)")
        }
    }
    
    func deletePlannedMeal(_ meal: PlannedMeal) async throws {
        // Note: PlannedMeal can be safely deleted even if dish is deleted
        // The relationship is optional, so we don't need to check references
        modelContext.delete(meal)
        
        do {
            try modelContext.save()
        } catch {
            throw DomainError.persistenceError(message: "Failed to delete planned meal: \(error.localizedDescription)")
        }
    }
    
    func fetchPlannedMeals(for date: Date) async throws -> [PlannedMeal] {
        let dayStart = Calendar.current.startOfDay(for: date)
        guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else {
            throw DomainError.invalidDate
        }
        
        let descriptor = FetchDescriptor<PlannedMeal>(
            predicate: #Predicate { meal in
                meal.date >= dayStart && meal.date < dayEnd
            },
            sortBy: [SortDescriptor(\.mealType)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch planned meals: \(error.localizedDescription)")
        }
    }
    
    func fetchPlannedMeals(in dateRange: ClosedRange<Date>) async throws -> [PlannedMeal] {
        let descriptor = FetchDescriptor<PlannedMeal>(
            predicate: #Predicate { meal in
                meal.date >= dateRange.lowerBound && meal.date <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.mealType)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch planned meals in date range: \(error.localizedDescription)")
        }
    }
    
    func fetchPlannedMeal(by id: PersistentIdentifier) async throws -> PlannedMeal? {
        let descriptor = FetchDescriptor<PlannedMeal>(
            predicate: #Predicate { $0.persistentModelID == id }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw DomainError.persistenceError(message: "Failed to fetch planned meal: \(error.localizedDescription)")
        }
    }
}

