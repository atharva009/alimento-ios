//
//  GroceryListView.swift
//  Alimento
//
//  Created on Phase 6, Enhanced in Phase 9
//

import SwiftUI
import SwiftData

struct GroceryListView: View {
    private let services: ServicesContainer
    @State private var viewModel: GroceryViewModel?

    init(services: ServicesContainer) {
        self.services = services
    }
    @State private var showingAddItem = false
    @State private var showingGenerateSheet = false
    @State private var editingItem: GroceryItem?
    @State private var selectedItem: GroceryItem?
    @State private var showingAddToInventory = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading && vm.groceryItems.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.groceryItems.isEmpty {
                        emptyStateView
                    } else {
                        groceryListContent(vm: vm)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingGenerateSheet = true
                        } label: {
                            Label("Generate List", systemImage: "sparkles")
                        }
                        
                        Button {
                            showingAddItem = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add or generate")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                if let vm = viewModel {
                    GroceryItemEditorView(viewModel: vm, item: nil)
                }
            }
            .sheet(isPresented: $showingGenerateSheet) {
                if let vm = viewModel {
                    GenerateGroceryListView(viewModel: vm)
                }
            }
            .sheet(item: $editingItem) { item in
                if let vm = viewModel {
                    GroceryItemEditorView(viewModel: vm, item: item)
                }
            }
            .sheet(item: $selectedItem) { item in
                if let vm = viewModel {
                    AddToInventoryView(viewModel: vm, item: item)
                }
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
                let vm = GroceryViewModel(
                    groceryService: services.groceryService,
                    plannerService: services.plannerService,
                    inventoryService: services.inventoryService
                )
                viewModel = vm
                await vm.loadActiveList()
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text("No grocery items")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Generate a list from your planned meals and inventory, or add items manually")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    showingGenerateSheet = true
                } label: {
                    Label("Generate List", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No grocery items. Generate a list from your planned meals and inventory, or add items manually")
    }
    
    private func groceryListContent(vm: GroceryViewModel) -> some View {
        List {
            // To Buy Section
            if !vm.toBuyItems.isEmpty {
                Section("To Buy") {
                    ForEach(vm.toBuyItems, id: \.persistentModelID) { item in
                        GroceryItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticFeedback.selection.play()
                                Task {
                                    await vm.togglePurchased(item)
                                }
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
                                .tint(.blue)
                            }
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
                            .accessibilityHint("Tap to mark as purchased, swipe left for actions")
                    }
                }
            }
            
            // Purchased Section
            if !vm.purchasedItems.isEmpty {
                Section("Purchased") {
                    ForEach(vm.purchasedItems, id: \.persistentModelID) { item in
                        GroceryItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    await vm.togglePurchased(item)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    selectedItem = item
                                    showingAddToInventory = true
                                } label: {
                                    Label("Add to Inventory", systemImage: "plus.circle")
                                }
                                .tint(.green)
                                
                                Button(role: .destructive) {
                                    Task {
                                        await vm.deleteItem(item)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Grocery Item Row

struct GroceryItemRow: View {
    let item: GroceryItem
    
    var reasonBadge: String? {
        switch item.reason {
        case "missing": return "Missing"
        case "low_stock": return "Low Stock"
        case "staple": return "Staple"
        case "manual": return nil
        default: return nil
        }
    }
    
    var priorityIcon: String? {
        switch item.priority {
        case 1: return "exclamationmark.circle.fill"
        case 2: return "circle.fill"
        case 3: return "circle"
        default: return nil
        }
    }
    
    var priorityColor: Color {
        switch item.priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isPurchased ? .green : .secondary)
                .font(.title3)
                .accessibilityLabel(item.isPurchased ? "Purchased" : "Not purchased")
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .strikethrough(item.isPurchased)
                    
                    if let icon = priorityIcon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(priorityColor)
                            .accessibilityLabel("Priority \(item.priority)")
                    }
                }
                
                HStack(spacing: 8) {
                    if item.quantity > 0 {
                        Text("\(String(format: "%.2f", item.quantity)) \(item.unit)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let badge = reasonBadge {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(badge)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var accessibilityLabel: String {
        var label = item.name
        if item.isPurchased {
            label += ", purchased"
        } else {
            label += ", not purchased"
        }
        if item.quantity > 0 {
            label += ", \(String(format: "%.2f", item.quantity)) \(item.unit)"
        }
        if let badge = reasonBadge {
            label += ", \(badge)"
        }
        return label
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return GroceryListView(services: services)
        .modelContainer(modelContainer)
}
