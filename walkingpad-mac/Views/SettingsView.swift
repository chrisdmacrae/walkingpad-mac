//
//  SettingsView.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    private enum Tabs: Hashable {
            case general
        }
    
    var body: some View {
        TabView {
            Form {
                KeyboardShortcuts.Recorder("Toggle treadmill on/off:", name: .toggleTreadmill)
                KeyboardShortcuts.Recorder("Decrease speed:", name: .decreaseSpeed)
                KeyboardShortcuts.Recorder("Increase speed:", name: .increaseSpeed)
            }
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

#Preview {
    SettingsView()
}
