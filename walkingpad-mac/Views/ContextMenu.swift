//
//  ContextMenu.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI

struct ContextMenu: View {
    var body: some View {
        VStack {
            SettingsLink {
                Text("Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            
            Divider()
            
            Button(action: {}) {
                Text("Quit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
    }
}

#Preview {
    ContextMenu()
}
