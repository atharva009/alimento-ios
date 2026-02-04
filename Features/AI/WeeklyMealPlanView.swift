//
//  WeeklyMealPlanView.swift
//  Alimento
//
//  Created on Phase 7
//

import SwiftUI
import SwiftData

struct WeeklyMealPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: ServicesContainer
    @Query private var userProfiles: [UserProfile]
    
    @State private var mealPlan: WeeklyMealPlan?
    @State private var state = AISuggestionState()
    
    var body: some View {
        NavigationStack {
            Group {
                if state.isLoading {
                    ProgressView("Generating weekly meal plan...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let plan = mealPlan {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(plan.days, id: \.date) { day in
                                DayMealPlanCard(dayPlan: day, macroEstimate: plan.dailyMacroSummary.first { $0.date == day.date })
                            }
                            
                            if !plan.prepPlan.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Meal Prep Plan")
                                        .font(.headline)
                                    
                                    ForEach(plan.prepPlan, id: \.self) { tip in
                                        Text("• \(tip)")
                                            .font(.subheadline)
                                    }
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Meal Plan", systemImage: "calendar")
                    } description: {
                        Text("Tap Generate to create an AI-powered weekly meal plan")
                    } actions: {
                        Button("Generate") {
                            generatePlan()
                        }
                    }
                }
            }
            .navigationTitle("Weekly Meal Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate") {
                        generatePlan()
                    }
                    .disabled(state.isLoading)
                }
            }
            .appAlert($state.alert)
        }
    }
    
    private func generatePlan() {
        state.startLoading()
        let profile = userProfiles.first ?? UserProfile()
        
        Task {
            do {
                let plan = try await services.aiService.generateWeeklyMealPlan(
                    preferences: profile,
                    mealsPerDay: 3,
                    busyDays: nil
                )
                await MainActor.run {
                    self.mealPlan = plan
                    state.finishLoading()
                }
            } catch {
                await MainActor.run {
                    state.setError(error, retryAction: { generatePlan() })
                }
            }
        }
    }
}

struct DayMealPlanCard: View {
    let dayPlan: DayMealPlan
    let macroEstimate: DailyMacroSummary?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dayPlan.date)
                .font(.headline)
            
            if let breakfast = dayPlan.meals.breakfast {
                MealRow(title: breakfast, mealType: "Breakfast")
            }
            
            if let lunch = dayPlan.meals.lunch {
                MealRow(title: lunch, mealType: "Lunch")
            }
            
            if let dinner = dayPlan.meals.dinner {
                MealRow(title: dinner, mealType: "Dinner")
            }
            
            if let snack = dayPlan.meals.snack {
                MealRow(title: snack, mealType: "Snack")
            }
            
            if let macros = macroEstimate {
                HStack {
                    Text("\(macros.calories) cal")
                    Text("•")
                    Text("P: \(Int(macros.proteinG))g")
                    Text("•")
                    Text("C: \(Int(macros.carbsG))g")
                    Text("•")
                    Text("F: \(Int(macros.fatG))g")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

struct MealRow: View {
    let title: String
    let mealType: String
    
    var body: some View {
        HStack {
            Text(mealType)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text(title)
                .font(.subheadline)
        }
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return WeeklyMealPlanView()
        .modelContainer(modelContainer)
        .environmentObject(services)
}
