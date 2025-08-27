//
//  FavoriteDevice.swift
//  blist
//
//  Created by Brian Greeson on 8/27/25.
//

import Foundation
import SwiftData

@Model
class FavoriteDevice: Identifiable {
    var id: UUID = UUID()
    var name: String
    var rssi: Int
    var lastUpdated: Date
    var createdAt: Date
    
    init(name: String, rssi: Int, lastUpdated: Date = Date()) {
        self.name = name
        self.rssi = rssi
        self.lastUpdated = Date()
        self.createdAt = Date()
    }
}
