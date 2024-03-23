//
//  ContentView.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-22.
//

import SwiftUI
import SwiftData
import CompactSlider

struct ContentView: View {
    @ObservedObject var service: WalkingPadService
    @Environment(\.modelContext) private var modelContext
    
    @State private var macAddress: String?
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .trailing, spacing: 8) {
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
        }
        .padding(8)
        .frame(width: 300, height: 200)
        .background(.windowBackground)
        .focusEffectDisabled()
    }
        
}

struct TreadmillControls : View {
    @ObservedObject var treadmill: TreadmillService
    @State var currentSpeed = 0.0
    @State var countdown: Int = 0
    @State private var isEditing = false
    
    var body : some View {
        VStack(spacing: 8) {
            if (treadmill.isBluetoothConnected == false) {
                Spinner(text: "Connecting to your Treadmill...")
                    .onChange(of: treadmill.isWSConnected) {
                        if (treadmill.isWSConnected) {
                            treadmill.connect()
                        }
                    }
            }
            else {
                if (treadmill.isRunning == true) {
                    VStack(spacing: 8) {
                        Container() {
                            HStack {
                                Image(systemName: "timer")
                                Spacer()
                                Text(String(treadmill.stats.time))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Container() {
                                HStack {
                                    Image(systemName: "shoeprints.fill")
                                    Spacer()
                                    Text(String(treadmill.stats.steps))
                                }
                            }
                            
                            Container() {
                                HStack {
                                    Image(systemName: "lines.measurement.horizontal")
                                    Spacer()
                                    Text(String(treadmill.stats.distance))
                                }
                            }
                        }
                        
                        Container() {
                            HStack(spacing: 8) {
                                Button(action: {
                                    treadmill.decreaseSpeed(increment: 5)
                                }) {
                                    Label() {
                                        Text("Decrease speed")
                                            .opacity(0)
                                            .frame(width: 0, height: 0)
                                    } icon: {
                                        Image(systemName: "minus.circle")
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                VStack {
                                    CompactSlider(value: $currentSpeed, in: 1...60, step: 1) {
                                        Image(systemName: "figure.run")
                                            Spacer()
                                            Text(String(format: "%.2f", currentSpeed / 10))
                                        }
                                }
                                
                                Button(action: {
                                    treadmill.increaseSpeed(increment: 5)
                                }) {
                                    Label() {
                                        Text("Increase speed")
                                            .opacity(0)
                                            .frame(width: 0, height: 0)
                                    } icon: {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onAppear() {
                        Task {
                            await treadmill.streamStats()
                        }
                    }
                }
                
                if (treadmill.isRunning == true) {
                    Button(action: {
                        treadmill.stop()
                    }) {
                        Text("Stop")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                else {
                    Container() {
                        if (countdown == 0) {
                            Button(action: {
                                treadmill.start()
                                countdown = 3
                            }) {
                                Text("Start")
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        } else {
                            Text(String(countdown))
                                .font(.system(size: 24))
                                .onAppear() {
                                    Task {
                                        await countDown()
                                    }
                                }
                        }
                    }
                }
            }
        }
        .onChange(of: treadmill.currentSpeed) {
            currentSpeed = Double(treadmill.currentSpeed)
        }
        .onChange(of: currentSpeed) {
            treadmill.setSpeed(speed: Int(currentSpeed))
        }
        .frame(maxWidth: .infinity)
    }
    
    func countDown() async {
        while (countdown > 0) {
            do {
                try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            } catch {
                // uh-oh
            }
            
            countdown = countdown - 1
        }
    }
}

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
    ContentView(service: try! WalkingPadService())
        .modelContainer(for: [], inMemory: true)
}
