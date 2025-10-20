//
//  blistApp.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//

import SwiftUI
import SwiftData
@main
struct signalMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FavoriteDevice.self)
    }
}


