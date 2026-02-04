//
//  PlannerViewModel.swift
//  Alimento
//
//  Created on Phase 5
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published var currentWeekStartDate: Date = Calendar.current.startOfWeek(for: Date())
    @Published var plannedMeals: [PlannedMeal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let plannerService: PlannerService
    private let dishLogService: DishLogService
    
    init(plannerService: PlannerService, dishLogService: DishLogService) {
        self.plannerService = plannerService
        self.dishLogService = dishLogService
    }
    
    var currentWeekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStartDate)!
    }
    
    var weekDateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: currentWeekStartDate)
        let end = formatter.string(from: currentWeekEndDate)
        return "\(start) – \(end)"
    }
    
    var daysInWeek: [Date] {
        (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: currentWeekStartDate)
        }
    }
    
    func mealsForDay(_ date: Date, mealType: String) -> [PlannedMeal] {
        plannedMeals.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.mealType == mealType
        }.sorted { $0.title < $1.title }
    }
    
    func fetchPlannedMeals() async {
        isLoading = true
        errorMessage = nil
        showingError = false
        do {
            let meals = try await plannerService.fetchPlannedMeals(in: currentWeekStartDate...currentWeekEndDate)
            self.plannedMeals = meals
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
        isLoading = false
    }
    
    func addPlannedMeal(date: Date, mealType: String, title: String, dish: Dish?) async {
        errorMessage = nil
        showingError = false
        do {
            _ = try await plannerService.createPlannedMeal(date: date, mealType: mealType, title: title, dish: dish, ingredientNames: [])
            await fetchPlannedMeals()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
    
    func updatePlannedMeal(_ meal: PlannedMeal, date: Date, mealType: String, title: String, dish: Dish?) async {
        errorMessage = nil
        showingError = false
        do {
            meal.date = date
            meal.mealType = mealType
            meal.title = title
            meal.dish = dish
            try await plannerService.updatePlannedMeal(meal)
            await fetchPlannedMeals()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
    
    func deletePlannedMeal(_ meal: PlannedMeal) async {
        errorMessage = nil
        showingError = false
        do {
            try await plannerService.deletePlannedMeal(meal)
            await fetchPlannedMeals()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
    
    func goToPreviousWeek() {
        currentWeekStartDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStartDate)!
        Task { await fetchPlannedMeals() }
    }
    
    func goToNextWeek() {
        currentWeekStartDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStartDate)!
        Task { await fetchPlannedMeals() }
    }
    
    func goToToday() {
        currentWeekStartDate = Calendar.current.startOfWeek(for: Date())
        Task { await fetchPlannedMeals() }
    }
    
    func fetchAllDishes() async -> [Dish] {
        do {
            return try await dishLogService.fetchAllDishes()
        } catch {
            return []
        }
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
}
