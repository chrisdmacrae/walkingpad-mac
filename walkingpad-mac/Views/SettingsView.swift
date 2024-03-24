//
//  SettingsView.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle treadmill on/off:", name: .toggleTreadmill)
            KeyboardShortcuts.Recorder("Decrease speed:", name: .decreaseSpeed)
            KeyboardShortcuts.Recorder("Increase speed:", name: .increaseSpeed)
        }
        .frame(width: 768, height: 480)
    }
}

#Preview {
    SettingsView()
}
