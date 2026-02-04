//
//  InsightsView.swift
//  Alimento
//
//  Created on Phase 9
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var inventoryItems: [InventoryItem]
    @Query private var plannedMeals: [PlannedMeal]
    @Query private var groceryLists: [GroceryList]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Inventory by Location Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Inventory by Location")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if inventoryItems.isEmpty {
                            EmptyChartView(message: "No inventory items to display")
                                .padding(.horizontal)
                        } else {
                            Chart {
                                ForEach(locationData, id: \.location) { data in
                                    BarMark(
                                        x: .value("Location", data.location.capitalized),
                                        y: .value("Count", data.count)
                                    )
                                    .foregroundStyle(by: .value("Location", data.location))
                                    .accessibilityLabel("\(data.location): \(data.count) items")
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Inventory by location chart. \(locationData.map { "\($0.location.capitalized): \($0.count) items" }.joined(separator: ", "))")
                        }
                    }
                    .padding(.top)
                    
                    // Grocery Items by Reason Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Grocery Items by Reason")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if groceryItemData.isEmpty {
                            EmptyChartView(message: "No grocery items to display")
                                .padding(.horizontal)
                        } else {
                            Chart {
                                ForEach(groceryItemData, id: \.reason) { data in
                                    BarMark(
                                        x: .value("Reason", data.reason),
                                        y: .value("Count", data.count)
                                    )
                                    .foregroundStyle(by: .value("Reason", data.reason))
                                    .accessibilityLabel("\(data.reason): \(data.count) items")
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Grocery items by reason chart. \(groceryItemData.map { "\($0.reason): \($0.count) items" }.joined(separator: ", "))")
                        }
                    }
                    
                    // Planned Meals per Day Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Planned Meals This Week")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if weeklyMealData.isEmpty {
                            EmptyChartView(message: "No planned meals this week")
                                .padding(.horizontal)
                        } else {
                            Chart {
                                ForEach(weeklyMealData, id: \.day) { data in
                                    BarMark(
                                        x: .value("Day", data.dayName),
                                        y: .value("Meals", data.count)
                                    )
                                    .foregroundStyle(.blue)
                                    .accessibilityLabel("\(data.dayName): \(data.count) meals")
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Planned meals per day chart. \(weeklyMealData.map { "\($0.dayName): \($0.count) meals" }.joined(separator: ", "))")
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Computed Data
    
    private var locationData: [LocationData] {
        let grouped = Dictionary(grouping: inventoryItems) { $0.location }
        return ["pantry", "fridge", "freezer"].map { location in
            LocationData(location: location, count: grouped[location]?.count ?? 0)
        }
    }
    
    private var groceryItemData: [ReasonData] {
        guard let activeList = groceryLists.first,
              let items = activeList.items else {
            return []
        }
        
        let grouped = Dictionary(grouping: items) { $0.reason }
        return grouped.map { (reason, items) in
            ReasonData(reason: reason, count: items.count)
        }.sorted { $0.reason < $1.reason }
    }
    
    private var weeklyMealData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var dayData: [DayData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            
            let meals = plannedMeals.filter { $0.date >= day && $0.date < dayEnd }
            let dayName = formatter.string(from: day)
            
            dayData.append(DayData(day: day, dayName: dayName, count: meals.count))
        }
        
        return dayData
    }
}

struct LocationData {
    let location: String
    let count: Int
}

struct ReasonData {
    let reason: String
    let count: Int
}

struct DayData {
    let day: Date
    let dayName: String
    let count: Int
}

struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [
            InventoryItem.self,
            PlannedMeal.self,
            GroceryList.self,
            GroceryItem.self
        ])
}

