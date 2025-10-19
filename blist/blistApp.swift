//
//  blistApp.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//

import SwiftUI
import SwiftData
@main
struct blistApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().onAppear {
               print("main view appearing")
            }
        }
        .modelContainer(for: FavoriteDevice.self)
    }
}


