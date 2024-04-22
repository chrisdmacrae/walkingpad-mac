//
//  ContentView.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-22.
//

import SwiftUI
import SwiftData
import TreadmillController

//class WalkingPadService : ObservableObject {
//    @Published var isScanning = false
//    @Published var isConnecting = false
//    @Published var treadmill: TreadmillService?
//    private var wsProcess: ChildProcess<UnspecifiedInputSource, PipeOutputDestination, PipeOutputDestination>?
//
//    func scan() async  -> WalkingPadDevice? {
//        await MainActor.run {
//            isScanning = true
//        }
//
//        var device: WalkingPadDevice? = nil
//        let output = try! Command.init(executablePath: pythonFilePath)
//            .addArgument(scanPath!)
//            .waitForOutput()
//        let dirtyMatcher = try! NSRegularExpression(pattern: "Device: \\[ 0\\], (.*-.*-.*-.*), (.*),")
//        let stdout = output.stdout
//
//        if let match = dirtyMatcher.firstMatch(in: stdout, range: NSMakeRange(0, stdout.count)) {
//            let groups = match.groups(testedString: stdout)
//            let lastTwo = Array(groups.suffix(2))
//            let mac = lastTwo.first!
//            let model = lastTwo.last!
//
//            device = WalkingPadDevice(mac: mac, model: model)
//        }
//
//        await MainActor.run {
//            isScanning = false
//        }
//
//        return device
//    }
//
//    func connect(macAddress: String) async {
//        await MainActor.run {
//            isConnecting = true
//        }
//
//        wsProcess = try! Command.init(executablePath: pythonFilePath)
//            .addArgument(wsServerPath!)
//            .addArgument("--mac=\(macAddress)")
//            .setStdout(.pipe)
//            .setStderr(.pipe)
//            .spawn()
//
//        do {
//            await MainActor.run {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                    if (self.treadmill == nil) {
//                        self.disconnect()
//                    }
//                }
//            }
//
//            for try await line in wsProcess!.stderr.lines {
//                if (line.contains("server listening on 127.0.0.1:8765")) {
//                    await MainActor.run {
//                        isConnecting = false
//                        treadmill = TreadmillService()
//                    }
//                }
//            }
//        } catch {
//            await MainActor.run {
//                isConnecting = false
//            }
//
//            disconnect()
//        }
//    }
//
//    func disconnect() {
//        wsProcess?.terminate()
//        treadmill = nil
//    }
//}




struct ControlView: View {
    // @ObservedObject var service: WalkingPadService
    @Environment(\.modelContext) private var modelContext
    // @State private var device: WalkingPadDevice?
	
	@State var treadmill: Treadmill
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
					if (treadmill.isConnected) {
                TreadmillControls(treadmill: treadmill, context: modelContext)
            }
            else if (treadmill.isScanning) {
                Spinner(text: "Connecting to your Treadmill...")
            }
        }
//        .onAppear() {
//            Task {
//                while (device == nil) {
//                    device = await service.scan()
//                }
//            }
//        }
//        .onChange(of: device) {
//            if (device?.mac != nil) {
//                Task {
//                    await service.connect(macAddress: device!.mac)
//                }
//            } else {
//                Task {
//                    device = await service.scan()
//                }
//            }
//        }
        .padding(8)
        .frame(minWidth: 300, minHeight: 100)
        .background(.windowBackground)
    }
        
}

//#Preview {
//    ControlView()
//        .modelContainer(for: [], inMemory: true)
//}
