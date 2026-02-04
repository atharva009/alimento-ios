//
//  DishListView.swift
//  Alimento
//
//  Created on Phase 4
//

import SwiftUI
import SwiftData

struct DishListView: View {
    let dishes: [Dish]
    let viewModel: DishLogViewModel
    
    var body: some View {
        List {
            ForEach(dishes) { dish in
                NavigationLink {
                    DishDetailView(dish: dish)
                } label: {
                    DishRow(dish: dish)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteDish(dish)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

struct DishRow: View {
    let dish: Dish
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dish.name)
                .font(.headline)
            
            HStack {
                Text("\(dish.servings) servings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(dish.dateCooked, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DishListView(dishes: [], viewModel: DishLogViewModel(dishLogService: DishLogServiceImpl(modelContext: ModelContext(try! ModelContainer(for: Dish.self)), inventoryService: InventoryServiceImpl(modelContext: ModelContext(try! ModelContainer(for: Dish.self))))))
        .modelContainer(for: [Dish.self])
}

