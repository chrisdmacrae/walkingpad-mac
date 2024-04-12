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
    @ObservedObject var treadmill: Treadmill
    @ObservedObject private var viewModel: TreadmillViewModel
    @State private var currentSpeed = 0.0
    @State private var isEditing = false
    @State private var sliderState: CompactSliderState = .zero
        
    init(treadmill: Treadmill, context: ModelContext) {
        self.treadmill = treadmill
        viewModel = TreadmillViewModel(treadmill: treadmill, context: context)
    }
    
    var body : some View {
        VStack(spacing: 8) {
//            if (treadmill.isBluetoothConnected == false) {
//                Spinner(text: "Connecting to your Treadmill...")
//                    .onChange(of: treadmill.isWSConnected) {
//                        if (treadmill.isWSConnected) {
//                            treadmill.connect()
//                        }
//                    }
//            }
            //else {
                if (treadmill.isRunning == true) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Container() {
                                HStack {
                                    Image(systemName: "timer")
                                    Spacer()
																	Text(String(treadmill.stats?.currentRunningTime ?? 0))
                                }
                            }
                            
                            Container() {
                                HStack {
                                    Image(systemName: "shoeprints.fill")
                                    Spacer()
																	Text(String(treadmill.stats?.currentSteps ?? 0))
                                }
                            }
                            
                            Container() {
                                HStack {
                                    Image(systemName: "lines.measurement.horizontal")
                                    Spacer()
																	Text(String(treadmill.stats?.currentDistance ?? 0))
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
                                .padding(.top, 4)
                                .padding(.bottom, 2)
                                
                                ZStack {
                                    GeometryReader { geometry in
                                        CompactSlider(value: $viewModel.desiredSpeed, in: 5...60, step: 1, state: $sliderState) {
                                            Image(systemName: "figure.run")
                                            Spacer()
                                            Text(String(format: "%.2f", currentSpeed / 10))
                                        }
                                        .offset(x: 0, y: 2)
                                        .contentShape(.rect)
                                        
                                        
                                        GeometryReader { buttonGeometry in
                                            Text(String(format: "%.2f", viewModel.desiredSpeed / 10))
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(
                                                    Capsule().fill(Color.blue)
                                                )
                                                .offset(x: sliderState.dragLocationX.lower + (geometry.size.width / 2) - 12, y: -3)
                                                .offset(y: 4)
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
                                .padding(.vertical, 6)
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
                        StartState(viewModel: viewModel)
                    } else {
                        Container() {
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
       // }
//        .onChange(of: treadmill.isBluetoothConnected) {
//            if (treadmill.isBluetoothConnected) {
//                Task {
//                    await treadmill.streamStats()
//                }
//            }
//        }
//        .onChange(of: treadmill.currentSpeed) {
//            currentSpeed = Double(treadmill.currentSpeed)
//        }
//        .onChange(of: viewModel.desiredSpeed) {
//            viewModel.setSpeed(desiredSpeed: Int(viewModel.desiredSpeed))
//        }
        .frame(maxWidth: .infinity)
    }
}

struct StartState : View {
    @ObservedObject var viewModel: TreadmillViewModel
    @Query(filter: Session.todayPredicate())
    private var sessions: [Session]
    
    var body : some View {
        let totalSteps = sessions.reduce(0, { total, session in
            return total + session.steps
        })
        let totalTime = sessions.reduce(0, { total, session in
            return total + session.time
        })
        let totalDistance = sessions.reduce(0, { total, session in
            return total + session.distance
        })
        
        VStack(spacing: 8) {
            Text("Ready to walk?")
                .font(.system(size: 18, weight: .bold))
            Text("After starting, your treadmill will count down before it starts")
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            Container() {
                HStack {
                    Text(String("\(sessions.count) sessions today"))
                }
            }
            
            HStack(spacing: 8) {
                Container() {
                    HStack {
                        Image(systemName: "timer")
                        Spacer()
                        Text(String(totalTime))
                    }
                }
                
                Container() {
                    HStack {
                        Image(systemName: "shoeprints.fill")
                        Spacer()
                        Text(String(totalSteps))
                    }
                }
                
                Container() {
                    HStack {
                        Image(systemName: "lines.measurement.horizontal")
                        Spacer()
                        Text(String(totalDistance))
                    }
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
}

@MainActor
class TreadmillViewModel : ObservableObject {
    @ObservedObject var treadmill: Treadmill
    var context: ModelContext
    @Published var desiredSpeed = 20.0
    @Published var countdown: Int = 0
    
    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()
    private var isToggleEnabled = true
    private var isSpeedChangeEnabled = true
    private var session: Session?
    
    init(treadmill: Treadmill, context: ModelContext) {
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
			
			treadmill.treadmillController.setSpeed(Int(desiredSpeed))

        // treadmill.setSpeed(speed: desiredSpeed)
    }
    
    func decreaseSpeed() {
        guard isSpeedChangeEnabled else { return }
        guard treadmill.isRunning else { return }

        desiredSpeed -= 5
				
			treadmill.treadmillController.setSpeed(Int(desiredSpeed))
			
        // treadmill.setSpeed(speed: Int(desiredSpeed))
    }
    
    func increaseSpeed() {
        guard isSpeedChangeEnabled else { return }
        guard treadmill.isRunning else { return }
    
        desiredSpeed += 5
			treadmill.treadmillController.setSpeed(Int(desiredSpeed))
        // treadmill.setSpeed(speed: Int(desiredSpeed))
    }
    
    func start() {
        //treadmill.start()
			
			treadmill.treadmillController.selectManualMode()
			
			//usleep(700)
			
			treadmill.treadmillController.startBelt()
			
			treadmill.isRunning = true
			
        countdown = 5
        session = Session()
        // context.insert(session!)
    }
    
    func stop() {
			session?.steps = treadmill.stats?.currentSteps ?? 0
        session?.distance = Double(treadmill.stats?.currentDistance ?? 0)
			session?.time = Double(treadmill.stats?.currentRunningTime ?? 0)

			treadmill.treadmillController.stopBelt()
			treadmill.isRunning = false
			
			
        // treadmill.stop()
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

//#Preview {
//    TreadmillControls(treadmill: TreadmillService(), context: try! .init(.init(for: Session.self)))
//}
