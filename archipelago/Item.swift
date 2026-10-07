//
//  Item.swift
//  archipelago
//
//  Created by Francis Tan on 07/10/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
