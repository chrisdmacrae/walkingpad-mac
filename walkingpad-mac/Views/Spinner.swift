//
//  Spinner.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI

struct Spinner : View {
    var text: String?
    @State private var degreesRotating = 0.0
    
    var body : some View {
        HStack(alignment: .center) {
            VStack(spacing: 8) {
                Image(systemName: "rays")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(degreesRotating))
                    .onAppear {
                        withAnimation(.linear(duration: 1)
                            .speed(0.5).repeatForever(autoreverses: false)) {
                                degreesRotating = 360.0
                            }
                    }
                
                if (text != nil) {
                    Text(text!)
                }
            }
        }
    }
}

#Preview {
    Spinner()
}
