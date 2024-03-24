//
//  Container.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI

struct Container<Content : View> : View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background() {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.black.opacity(0.05))
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .stroke(.black.opacity(0.1), lineWidth: 2)
                .background() {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.black.opacity(0.2))
                        .blur(radius: 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    Container() {
        Text("hello world")
    }
}
