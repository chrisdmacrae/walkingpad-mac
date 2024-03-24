//
//  ContextMenu.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI

struct ContextMenu: View {
    var body: some View {
        VStack(alignment: .leading) {
            SettingsLink {
                Text("Settings")
            }
            .buttonStyle(ContentMenuButtonStyle())
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
            }
            .buttonStyle(ContentMenuButtonStyle())
        }
        .padding(8)
        .frame(width: 140)
    }
}

struct ContentMenuButtonStyle : ButtonStyle {
    @State var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            configuration.label
                .multilineTextAlignment(.leading)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
            
            Spacer()
        }
        .background() {
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? .blue.opacity(0.7) : .clear)
        }
        .onHover(perform: { hovering in
            isHovering = hovering
        })
    }
}


#Preview {
    ContextMenu()
}
