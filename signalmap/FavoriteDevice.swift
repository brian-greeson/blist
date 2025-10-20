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
    var lastUpdated: Date
    var createdAt: Date

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
        self.lastUpdated = Date()
        self.createdAt = Date()
    }
}

extension FavoriteDevice: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        "FavoriteDevice(name: \(name), id: \(id.uuidString.prefix(8))…, createdAt: \(createdAt.formatted(date: .abbreviated, time: .shortened)))"
    }

    var debugDescription: String {
        "FavoriteDevice(id: \(id.uuidString), name: \(name), createdAt: \(createdAt), lastUpdated: \(lastUpdated)"
    }
}
