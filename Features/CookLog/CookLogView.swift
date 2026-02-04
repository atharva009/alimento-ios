//
//  CookLogView.swift
//  Alimento
//
//  Created on Phase 4
//

import SwiftUI
import SwiftData

struct CookLogView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var services: ServicesContainer
    
    @State private var viewModel: DishLogViewModel?
    @State private var showingAddDish = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading && vm.dishes.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.dishes.isEmpty {
                        ContentUnavailableView {
                            Label("No Dishes", systemImage: "fork.knife")
                        } description: {
                            Text("Log dishes you've cooked to track your cooking history")
                        } actions: {
                            Button("Log Dish") {
                                showingAddDish = true
                            }
                        }
                    } else {
                        List {
                            ForEach(vm.dishes) { dish in
                                NavigationLink {
                                    DishDetailView(dish: dish)
                                } label: {
                                    DishRow(dish: dish)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        HapticFeedback.warning.play()
                                        Task {
                                            await vm.deleteDish(dish)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task {
                                            await vm.deleteDish(dish)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .accessibilityLabel("Dish: \(dish.name)")
                                .accessibilityHint("Swipe left to delete")
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Cook Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDish = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Log dish")
                    }
                }
            }
            .sheet(isPresented: $showingAddDish) {
                LogDishFormView()
                    .environmentObject(services)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel?.showingError ?? false },
                set: { if !$0 { viewModel?.showingError = false } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel?.errorMessage ?? "An error occurred")
            }
            .task {
                let vm = DishLogViewModel(dishLogService: services.dishLogService)
                viewModel = vm
                await vm.loadDishes()
            }
        }
    }
}

#Preview {
    CookLogView()
        .modelContainer(for: [Dish.self, DishIngredient.self, InventoryItem.self])
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: Dish.self))))
}
