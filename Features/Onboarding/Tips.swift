//
//  Tips.swift
//  Alimento
//
//  Created on Phase 9
//

import Foundation
import TipKit

struct InventoryAddTip: Tip {
    var title: Text {
        Text("Quick Add")
    }
    
    var message: Text? {
        Text("Use the Dashboard quick action to quickly add inventory items")
    }
    
    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }
}

struct PlannerAddMealTip: Tip {
    var title: Text {
        Text("Plan Your Meals")
    }
    
    var message: Text? {
        Text("Tap the + button to add meals to your weekly plan")
    }
    
    var image: Image? {
        Image(systemName: "calendar.badge.plus")
    }
}

struct GenerateGroceryListTip: Tip {
    var title: Text {
        Text("Smart Grocery Lists")
    }
    
    var message: Text? {
        Text("Generate grocery lists automatically from your planned meals and low stock items")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
}

