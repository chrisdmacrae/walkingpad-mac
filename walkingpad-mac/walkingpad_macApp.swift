//
//  walkingpad_macApp.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-22.
//

import SwiftUI
import SwiftData

@main
struct walkingpad_macApp: App {
    @ObservedObject private var service = try! WalkingPadService()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        MenuBarExtra("WalkingPad Mac") {
            ContentView(service: service)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)
        
        Settings {
            SettingsView()
        }
    }
}
