//
//  TreadmillControls.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SwiftUI
import SwiftData
import KeyboardShortcuts
import CompactSlider
import Combine


struct TreadmillControls : View {
    @ObservedObject var treadmill: TreadmillService
    @ObservedObject private var viewModel: TreadmillViewModel
    @State private var currentSpeed = 0.0
    @State private var desiredSpeed = 20.0
    @State private var isEditing = false
    @State private var sliderState: CompactSliderState = .zero
    
    @Query(
        filter: Session.todayPredicate()
    )
    private var sessions: [Session]
    
    init(treadmill: TreadmillService, context: ModelContext) {
        self.treadmill = treadmill
        viewModel = TreadmillViewModel(treadmill: treadmill, context: context)
    }
    
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
                                    viewModel.decreaseSpeed()
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
                                
                                ZStack {
                                    GeometryReader { geometry in
                                        CompactSlider(value: $desiredSpeed, in: 5...60, step: 1, state: $sliderState) {
                                            Image(systemName: "figure.run")
                                            Spacer()
                                            Text(String(format: "%.2f", currentSpeed / 10))
                                        }
                                        .contentShape(.rect)
                                        
                                        
                                        GeometryReader { buttonGeometry in
                                            Text(String(format: "%.2f", desiredSpeed / 10))
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(
                                                    Capsule().fill(Color.blue)
                                                )
                                                .offset(x: sliderState.dragLocationX.lower + (geometry.size.width / 2) - 12, y: -3)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    viewModel.increaseSpeed()
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
                }
                
                if (treadmill.isRunning == true) {
                    Button(action: {
                        viewModel.stop()
                    }) {
                        Text("Stop")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                else {
                    if (viewModel.countdown == 0) {
                        Container() {
                            VStack(spacing: 8) {
                                Text("Ready to walk?")
                                    .font(.system(size: 18, weight: .bold))
                                Text("After starting, your treadmill will count down before it starts")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.8))
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Container() {
                                        Text("\(sessions.count) sessions today")
                                    }
                                }
                                
                                Spacer()
                                Button(action: {
                                    viewModel.start()
                                }) {
                                    Text("Start")
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                        }
                    } else {
                        Text(String(viewModel.countdown))
                            .font(.system(size: 24))
                            .onAppear() {
                                Task {
                                    await viewModel.countDown()
                                }
                            }
                    }
                }
            }
        }
        .onChange(of: treadmill.isBluetoothConnected) {
            if (treadmill.isBluetoothConnected) {
                Task {
                    await treadmill.streamStats()
                }
            }
        }
        .onChange(of: treadmill.currentSpeed) {
            currentSpeed = Double(treadmill.currentSpeed)
        }
        .onChange(of: desiredSpeed) {
            viewModel.setSpeed(desiredSpeed: Int(desiredSpeed))
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
class TreadmillViewModel : ObservableObject {
    @ObservedObject var treadmill: TreadmillService
    var context: ModelContext
    @Published var countdown: Int = 0
    
    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()
    private var isToggleEnabled = true
    private var isSpeedChangeEnabled = true
    private var session: Session?
    
    init(treadmill: TreadmillService, context: ModelContext) {
        self.treadmill = treadmill
        self.context = context
        
        timer.sink { _ in
            self.isToggleEnabled = true
            self.isSpeedChangeEnabled = true
        }
        .store(in: &cancellables)

        KeyboardShortcuts.onKeyUp(for: .toggleTreadmill) { [self] in
            toggle()
        }
        
        KeyboardShortcuts.onKeyUp(for: .decreaseSpeed) { [self] in
            decreaseSpeed()
        }
        
        KeyboardShortcuts.onKeyUp(for: .increaseSpeed) { [self] in
            increaseSpeed()
        }
    }
    
    func toggle() {
        guard isToggleEnabled else { return }
        
        if (treadmill.isRunning) {
            stop()
        }
        else {
            start()
        }
    }
    
    func setSpeed(desiredSpeed: Int) {
        guard isSpeedChangeEnabled else { return }
        guard treadmill.isRunning else { return }

        treadmill.setSpeed(speed: desiredSpeed)
    }
    
    func decreaseSpeed() {
        guard isSpeedChangeEnabled else { return }
        guard treadmill.isRunning else { return }

        treadmill.decreaseSpeed(increment: 5)
    }
    
    func increaseSpeed() {
        guard isSpeedChangeEnabled else { return }
        guard treadmill.isRunning else { return }

        treadmill.increaseSpeed(increment: 5)
    }
    
    func start() {
        treadmill.start()
        countdown = 5
        session = Session()
        context.insert(session!)
    }
    
    func stop() {
        session?.steps = treadmill.stats.steps
        session?.distance = treadmill.stats.distance
        session?.time = treadmill.stats.time

        treadmill.stop()
        countdown = 0
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

#Preview {
    TreadmillControls(treadmill: TreadmillService(), context: try! .init(.init(for: Session.self)))
}
