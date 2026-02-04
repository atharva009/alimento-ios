//
//  PlannerWeekView.swift
//  Alimento
//
//  Created on Phase 5
//

import SwiftUI
import SwiftData

struct PlannerWeekView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var viewModel: PlannerViewModel
    @State private var showingAddMeal = false
    @State private var selectedDate: Date?
    @State private var selectedMealType: String?
    @State private var editingMeal: PlannedMeal?
    
    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    private var dayNames: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        return viewModel.daysInWeek.map { date in
            formatter.string(from: date)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Week header
                    HStack {
                        Button {
                            viewModel.goToPreviousWeek()
                        } label: {
                            Image(systemName: "chevron.left")
                                .accessibilityLabel("Previous week")
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(viewModel.weekDateRangeString)
                                .font(.headline)
                            
                            Button("Today") {
                                viewModel.goToToday()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.goToNextWeek()
                        } label: {
                            Image(systemName: "chevron.right")
                                .accessibilityLabel("Next week")
                        }
                    }
                    .padding()
                    
                    // Days stack (vertical)
                    if viewModel.plannedMeals.isEmpty && !viewModel.isLoading {
                        EmptyPlannerView(action: {
                            selectedDate = Date()
                            selectedMealType = nil
                            showingAddMeal = true
                        })
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(viewModel.daysInWeek.enumerated()), id: \.offset) { index, date in
                                DayCard(
                                    date: date,
                                    dayName: dayNames[index],
                                    viewModel: viewModel,
                                    onAddMeal: { mealType in
                                        selectedDate = date
                                        selectedMealType = mealType
                                        showingAddMeal = true
                                    },
                                    onEditMeal: { meal in
                                        editingMeal = meal
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedDate = Date()
                        selectedMealType = nil
                        showingAddMeal = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add planned meal")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                PlannedMealEditorView(
                    viewModel: viewModel,
                    initialDate: selectedDate ?? viewModel.currentWeekStartDate,
                    initialMealType: selectedMealType,
                    meal: nil
                )
            }
            .sheet(item: $editingMeal) { meal in
                PlannedMealEditorView(
                    viewModel: viewModel,
                    initialDate: meal.date,
                    initialMealType: meal.mealType,
                    meal: meal
                )
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .task {
                await viewModel.fetchPlannedMeals()
            }
        }
    }
}

struct DayCard: View {
    let date: Date
    let dayName: String
    let viewModel: PlannerViewModel
    let onAddMeal: (String) -> Void
    let onEditMeal: (PlannedMeal) -> Void
    
    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Day header (left side)
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isToday ? .blue : .secondary)
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.title2)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? .blue : .primary)
                
                // Month name for first day of month
                if Calendar.current.component(.day, from: date) == 1 {
                    Text(Calendar.current.dateComponents([.month], from: date).month.map { month in
                        DateFormatter().monthSymbols[month - 1]
                    } ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 60, alignment: .leading)
            
            Divider()
                .frame(height: 1)
            
            // Meal types (right side)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(mealTypes, id: \.self) { mealType in
                    MealTypeSection(
                        date: date,
                        mealType: mealType,
                        meals: viewModel.mealsForDay(date, mealType: mealType),
                        onAdd: { onAddMeal(mealType) },
                        onEdit: onEditMeal
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isToday ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MealTypeSection: View {
    let date: Date
    let mealType: String
    let meals: [PlannedMeal]
    let onAdd: () -> Void
    let onEdit: (PlannedMeal) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(mealType.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            if meals.isEmpty {
                Button {
                    onAdd()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption2)
                        Text("Add")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(meals) { meal in
                        PlannedMealRow(meal: meal, onTap: { onEdit(meal) })
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct PlannedMealRow: View {
    let meal: PlannedMeal
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Text(meal.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if meal.dish != nil {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Edit Meal", systemImage: "pencil")
            }
        }
        .accessibilityLabel("Planned meal: \(meal.title)")
        .accessibilityHint("Double tap to edit")
    }
}

struct EmptyPlannerView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text("No meals planned")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Start planning your meals to stay organized and reduce food waste")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Plan Your First Meal", action: action)
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No meals planned. Start planning your meals to stay organized and reduce food waste")
    }
}

#Preview {
    PlannerWeekView()
        .modelContainer(for: [PlannedMeal.self, Dish.self])
        .environmentObject(PlannerViewModel(plannerService: PlannerServiceImpl(modelContext: ModelContext(try! ModelContainer(for: PlannedMeal.self))), dishLogService: DishLogServiceImpl(modelContext: ModelContext(try! ModelContainer(for: PlannedMeal.self)), inventoryService: InventoryServiceImpl(modelContext: ModelContext(try! ModelContainer(for: PlannedMeal.self))))))
}
