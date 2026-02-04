//
//  InventoryView.swift
//  Alimento
//
//  Created on Phase 3
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var services: ServicesContainer
    
    @State private var viewModel: InventoryViewModel?
    @State private var showingAddItem = false
    @State private var editingItem: InventoryItem?
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading && vm.items.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.filteredItems.isEmpty {
                        ContentUnavailableView {
                            Label("No Items", systemImage: "cabinet")
                        } description: {
                            Text("Add items to your inventory to get started")
                        } actions: {
                            Button("Add Item") {
                                showingAddItem = true
                            }
                        }
                    } else {
                        List {
                            ForEach(vm.filteredItems) { item in
                                NavigationLink {
                                    ItemDetailView(item: item)
                                } label: {
                                    InventoryItemRow(item: item)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        HapticFeedback.warning.play()
                                        Task {
                                            await vm.deleteItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        HapticFeedback.selection.play()
                                        editingItem = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppTheme.accent)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.cardBackground)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 8)
                                )
                                .contextMenu {
                                    Button {
                                        editingItem = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        Task {
                                            await vm.deleteItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .accessibilityLabel("\(item.name), \(item.quantity) \(item.unit)")
                                .accessibilityHint("Swipe left for actions")
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.barBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add item")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditInventoryItemView(item: nil)
                    .environmentObject(services)
            }
            .sheet(item: $editingItem) { item in
                AddEditInventoryItemView(item: item)
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
                let vm = InventoryViewModel(inventoryService: services.inventoryService)
                viewModel = vm
                await vm.loadItems()
            }
        }
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                    .font(.headline)
                
                Spacer()
                
                if item.isLowStock {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Low stock")
                        .accessibilityAddTraits(.isStaticText)
                }
                
                if item.isExpiringSoon {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.red)
                        .accessibilityLabel("Expiring soon")
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            
            HStack {
                Text("\(String(format: "%.2f", item.quantity)) \(item.unit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(item.location.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItemDetailView: View {
    let item: InventoryItem
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: item.name)
                LabeledContent("Category", value: item.category)
                LabeledContent("Quantity", value: "\(String(format: "%.2f", item.quantity)) \(item.unit)")
                LabeledContent("Location", value: item.location.capitalized)
            }
            
            if let expiry = item.expiryDate {
                Section("Expiry") {
                    LabeledContent("Date", value: expiry, format: .dateTime)
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: [InventoryItem.self])
        .environmentObject(ServicesContainer(modelContext: ModelContext(try! ModelContainer(for: InventoryItem.self))))
}
