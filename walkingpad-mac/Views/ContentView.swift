//
//  ContentView.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI

struct ContentView: View {
    @Binding var menuType: AppMenuType
    @ObservedObject var service: WalkingPadService

    var body: some View {
        if (menuType == .control) {
            ControlView(service: service)
                .focusEffectDisabled()

        }
        else {
            ContextMenu()
                .focusEffectDisabled()
        }
    }
}

#Preview {
    ContentView(menuType: .constant(.context), service: try! WalkingPadService())
}
