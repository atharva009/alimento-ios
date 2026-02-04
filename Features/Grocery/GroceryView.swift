//
//  GroceryView.swift
//  Alimento
//
//  Created on Phase 6
//

import SwiftUI
import SwiftData

/// Tab entry point for Grocery. Passes the app’s `ServicesContainer` into the list so all grocery screens use the same container.
struct GroceryView: View {
    @EnvironmentObject private var services: ServicesContainer

    var body: some View {
        GroceryListView(services: services)
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return GroceryView()
        .modelContainer(modelContainer)
        .environmentObject(services)
}

