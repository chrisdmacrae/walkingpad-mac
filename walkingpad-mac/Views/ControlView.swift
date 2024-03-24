//
//  ContentView.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-22.
//

import SwiftUI
import SwiftData

struct ControlView: View {
    @ObservedObject var service: WalkingPadService
    @Environment(\.modelContext) private var modelContext    
    @State private var macAddress: String?
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if (service.treadmill != nil) {
                TreadmillControls(treadmill: service.treadmill!)
            }
            else if (service.isScanning || service.isConnecting || service.treadmill != nil) {
                Spinner(text: "Setting things up...")
            }
        }
        .onAppear() {
            Task {
                while (macAddress == nil) {
                    macAddress = await service.scan()
                }
            }
        }
        .onChange(of: macAddress) {
            if (macAddress != nil) {
                Task {
                    await service.connect(macAddress: macAddress!)
                }
            } else {
                Task {
                    macAddress = await service.scan()
                }
            }
        }
        .padding(8)
        .frame(width: 300, height: 200)
        .background(.windowBackground)
    }
        
}

#Preview {
    ControlView(service: try! WalkingPadService())
        .modelContainer(for: [], inMemory: true)
}
