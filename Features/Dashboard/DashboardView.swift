//
//  DashboardView.swift
//  Alimento
//
//  Created on Phase 1, Enhanced in Phase 9
//

import SwiftUI
import SwiftData
import TipKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var services: ServicesContainer
    
    @State private var viewModel: DashboardViewModel?
    @State private var showingMealSuggestions = false
    @State private var showingWeeklyPlan = false
    @State private var showingGrocerySuggestions = false
    @State private var showingAddInventory = false
    @State private var showingLogDish = false
    @State private var showingPlanMeal = false
    @State private var showingInsights = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards Section
                    if let vm = viewModel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                SummaryCard(
                                    title: "Low Stock",
                                    value: "\(vm.lowStockCount)",
                                    icon: "exclamationmark.triangle.fill",
                                    color: AppTheme.warning,
                                    destination: .inventory
                                )
                                
                                SummaryCard(
                                    title: "Expiring Soon",
                                    value: "\(vm.expiringSoonCount)",
                                    icon: "clock.fill",
                                    color: AppTheme.danger,
                                    destination: .inventory
                                )
                                
                                SummaryCard(
                                    title: "Today's Meals",
                                    value: "\(vm.todayMealsCount)",
                                    icon: "calendar",
                                    color: AppTheme.planner,
                                    destination: .planner
                                )
                                
                                SummaryCard(
                                    title: "Grocery Remaining",
                                    value: "\(vm.groceryRemainingCount)",
                                    icon: "cart.fill",
                                    color: AppTheme.grocery,
                                    destination: .grocery
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top)
                    }
                    
                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            QuickActionRow(
                                icon: "plus.circle.fill",
                                title: "Add Inventory Item",
                                color: AppTheme.inventory,
                                action: { showingAddInventory = true }
                            )
                            .popoverTip(InventoryAddTip(), arrowEdge: .bottom)
                            
                            QuickActionRow(
                                icon: "fork.knife",
                                title: "Log Dish",
                                color: AppTheme.cookLog,
                                action: { showingLogDish = true }
                            )
                            
                            QuickActionRow(
                                icon: "calendar.badge.plus",
                                title: "Plan Meal",
                                color: AppTheme.planner,
                                action: { showingPlanMeal = true }
                            )
                            .popoverTip(PlannerAddMealTip(), arrowEdge: .bottom)
                        }
                        .padding(.horizontal)
                        
                        // AI Quick Actions (if available)
                        if AIConfiguration.shared.hasAPIKey {
                            VStack(spacing: 8) {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                QuickActionRow(
                                    icon: "sparkles",
                                    title: "Suggest Meals",
                                    color: AppTheme.ai,
                                    action: { showingMealSuggestions = true }
                                )
                                
                                QuickActionRow(
                                    icon: "calendar.badge.plus",
                                    title: "Generate Weekly Plan",
                                    color: AppTheme.ai,
                                    action: { showingWeeklyPlan = true }
                                )
                                
                                QuickActionRow(
                                    icon: "cart.badge.plus",
                                    title: "Generate Grocery List",
                                    color: AppTheme.ai,
                                    action: { showingGrocerySuggestions = true }
                                )
                                .popoverTip(GenerateGroceryListTip(), arrowEdge: .bottom)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    // Next Up Section
                    if let vm = viewModel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Up")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal)
                            
                            if vm.todaysMeals.isEmpty {
                                EmptyNextUpView(action: { showingPlanMeal = true })
                                    .padding(.horizontal)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(["breakfast", "lunch", "dinner", "snack"], id: \.self) { mealType in
                                        let meals = vm.todaysMealsByType(mealType)
                                        if !meals.isEmpty {
                                            MealTypeGroup(mealType: mealType, meals: meals)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.bottom)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.screenBackground)
            .navigationTitle("Dashboard")
            .toolbarBackground(AppTheme.barBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingInsights = true
                        } label: {
                            Label("Insights", systemImage: "chart.bar.fill")
                        }
                        
                        // Privacy & AI Settings - uncomment after adding PrivacyAndAISettingsView.swift to Xcode target
                        NavigationLink {
                            PrivacyAndAISettingsView()
                        } label: {
                            Label("Privacy & AI", systemImage: "hand.raised.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("More options")
                    }
                }
            }
            .refreshable {
                await viewModel?.refresh()
            }
            .task {
                if viewModel == nil {
                    viewModel = DashboardViewModel(
                        modelContext: modelContext,
                        inventoryService: services.inventoryService,
                        plannerService: services.plannerService,
                        groceryService: services.groceryService
                    )
                }
                await viewModel?.refresh()
            }
            .sheet(isPresented: $showingMealSuggestions) {
                MealSuggestionsView()
            }
            .sheet(isPresented: $showingWeeklyPlan) {
                WeeklyMealPlanView()
            }
            .sheet(isPresented: $showingGrocerySuggestions) {
                GrocerySuggestionsView()
            }
            .sheet(isPresented: $showingAddInventory) {
                AddEditInventoryItemView(item: nil)
            }
            .sheet(isPresented: $showingLogDish) {
                LogDishFormView()
            }
            .sheet(isPresented: $showingPlanMeal) {
                PlannedMealEditorView(
                    viewModel: PlannerViewModel(
                        plannerService: services.plannerService,
                        dishLogService: services.dishLogService
                    ),
                    initialDate: Date(),
                    initialMealType: nil,
                    meal: nil
                )
            }
            .sheet(isPresented: $showingInsights) {
                InsightsView()
            }
        }
    }
}

enum DashboardDestination {
    case inventory
    case planner
    case grocery
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let destination: DashboardDestination
    
    var body: some View {
        Button {
            // Navigation handled by TabView selection
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(value)
                    .font(.title)
                    .bold()
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .themedCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint("Double tap to view \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .themedCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct EmptyNextUpView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No meals planned for today")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Plan your meals to stay organized")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Plan Meal", action: action)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .themedCard()
    }
}

struct MealTypeGroup: View {
    let mealType: String
    let meals: [PlannedMeal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mealType.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            ForEach(meals) { meal in
                HStack {
                    Text(meal.title)
                        .font(.body)
                    
                    Spacer()
                    
                    if meal.dish != nil {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(AppTheme.surfaceSecondary)
                .cornerRadius(8)
            }
        }
        .padding()
        .themedCard()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .themedCard()
    }
}

struct DataStatusRow: View {
    let label: String
    let count: Int
    let expected: Int
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if count >= expected {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                    Text("\(count)")
                        .bold()
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(AppTheme.warning)
                    Text("\(count)/\(expected)")
                }
            }
        }
        .font(.subheadline)
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return DashboardView()
        .modelContainer(modelContainer)
        .environmentObject(services)
}

