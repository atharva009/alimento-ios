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
    @Query private var userProfiles: [UserProfile]
    
    @State private var mealPlan: WeeklyMealPlan?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private var aiService: AIService {
        AIServiceImpl()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
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
                                .background(Color(.systemGray6))
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
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func generatePlan() {
        isLoading = true
        errorMessage = nil
        
        let profile = userProfiles.first ?? UserProfile()
        
        Task {
            do {
                let plan = try await aiService.generateWeeklyMealPlan(
                    preferences: profile,
                    mealsPerDay: 3,
                    busyDays: nil
                )
                await MainActor.run {
                    self.mealPlan = plan
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
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
        .background(Color(.systemGray6))
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
    WeeklyMealPlanView()
        .modelContainer(for: [UserProfile.self])
}

