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
    @State private var device: WalkingPadDevice?
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if (service.treadmill != nil) {
                TreadmillControls(treadmill: service.treadmill!, context: modelContext)
            }
            else if (service.isScanning || service.isConnecting || service.treadmill != nil) {
                Spinner(text: "Connecting to your Treadmill...")
            }
        }
        .onAppear() {
            Task {
                while (device == nil) {
                    device = await service.scan()
                }
            }
        }
        .onChange(of: device) {
            if (device?.mac != nil) {
                Task {
                    await service.connect(macAddress: device!.mac)
                }
            } else {
                Task {
                    device = await service.scan()
                }
            }
        }
        .padding(8)
        .frame(minWidth: 300, minHeight: 100)
        .background(.windowBackground)
    }
        
}

#Preview {
    ControlView(service: try! WalkingPadService())
        .modelContainer(for: [], inMemory: true)
}
