//
//  GroceryList.swift
//  Alimento
//
//  Created on Phase 1
//

import Foundation
import SwiftData

@Model
final class GroceryList {
    var generatedAt: Date
    var daysAhead: Int // Number of days this list covers
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var items: [GroceryItem]?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        generatedAt: Date = Date(),
        daysAhead: Int = 7
    ) {
        self.generatedAt = generatedAt
        self.daysAhead = daysAhead
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

