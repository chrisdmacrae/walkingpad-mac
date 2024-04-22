//
//  Server.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SystemPackage
import Foundation
import SwiftCommand

//let pythonPath = Bundle.main.path(forResource: "python-lib/bin/python3", ofType: "")
//let pythonFilePath = FilePath(pythonPath!)
//let scanPath = Bundle.main.path(forResource: "python-lib/src/scan", ofType: "py")
//let wsServerPath = Bundle.main.path(forResource: "python-lib/src/wsserver", ofType: "py")
//
//struct WalkingPadDevice : Equatable {
//    var mac: String
//    var model: String
//}
//
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
