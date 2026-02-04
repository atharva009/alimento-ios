//
//  DishPickerView.swift
//  Alimento
//
//  Created on Phase 5
//

import SwiftUI
import SwiftData

struct DishPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dish.dateCooked, order: .reverse) private var dishes: [Dish]
    @Binding var selectedDish: Dish?
    
    @State private var searchText = ""
    
    // Memoized filtered dishes to avoid recomputation in body
    private var filteredDishes: [Dish] {
        if searchText.isEmpty {
            return dishes
        }
        let lowercasedSearch = searchText.lowercased()
        return dishes.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if dishes.isEmpty {
                    ContentUnavailableView {
                        Label("No Dishes", systemImage: "fork.knife")
                    } description: {
                        Text("Log dishes in Cook Log first to link them to planned meals")
                    }
                } else {
                    List {
                        ForEach(filteredDishes) { dish in
                            Button {
                                selectedDish = dish
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(dish.name)
                                            .font(.headline)
                                        Text(dish.dateCooked, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedDish?.persistentModelID == dish.persistentModelID {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search dishes")
                }
            }
            .navigationTitle("Select Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DishPickerView(selectedDish: .constant(nil))
        .modelContainer(for: [Dish.self])
}
