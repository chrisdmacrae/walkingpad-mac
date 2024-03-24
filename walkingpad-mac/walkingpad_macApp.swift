//
//  walkingpad_macApp.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-22.
//

import SwiftUI
import SwiftData
import MenuBarExtraAccess

@main
struct walkingpad_macApp: App {
    @ObservedObject private var service = try! WalkingPadService()
    @State var isMenuPresented: Bool = false
    @State var menuType = AppMenuType.control

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
        MenuBarExtra("WalkingPad") {
            ContentView(menuType: $menuType, service: service)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)
        .menuBarExtraAccess(isPresented: $isMenuPresented) { statusItem in
            NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
                if event.window == statusItem.button?.window {
                    menuType = AppMenuType.control
                }
                
                return event
            }
            
            NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
                if event.window == statusItem.button?.window {
                    menuType = AppMenuType.context
                }
                
                isMenuPresented = true

                
                return event
            }
        }
        
        Settings {
            SettingsView()
                .frame(width: 768, height: 480)
        }
    }
}

enum AppMenuType {
    case control
    case context
}
