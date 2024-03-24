//
//  Server.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import SystemPackage
import Foundation
import SwiftCommand

let pythonPath = Bundle.main.path(forResource: "python-lib/bin/python3", ofType: "")
let pythonFilePath = FilePath(pythonPath!)
let scanPath = Bundle.main.path(forResource: "python-lib/src/scan", ofType: "py")
let wsServerPath = Bundle.main.path(forResource: "python-lib/src/wsserver", ofType: "py")

class WalkingPadService : ObservableObject {
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var treadmill: TreadmillService?
    
    private var pidUrl: URL
    private var wsProcess: ChildProcess<UnspecifiedInputSource, PipeOutputDestination, PipeOutputDestination>?

    init() throws {
        pidUrl = try FileManager.default.url(for:.applicationSupportDirectory,
                                             in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: false)
        .appendingPathComponent("walkingpad-mac/wsserver.pid")
        
        print(pidUrl.path())
    }
    
    func scan() async  -> String? {
        await MainActor.run {
            isScanning = true
        }
        
        var macAddress: String? = nil
        let output = try! Command.init(executablePath: pythonFilePath)
            .addArgument(scanPath!)
            .waitForOutput()
        let dirtyMatcher = try! NSRegularExpression(pattern: "Device: \\[ 0\\], (.*-.*-.*-.*), WalkingPad,")
        let stdout = output.stdout
        
        if let match = dirtyMatcher.firstMatch(in: stdout, range: NSMakeRange(0, stdout.count)) {
            let groups = match.groups(testedString: stdout)
            
            macAddress = groups.last
        }
        
        await MainActor.run {
            isScanning = false
        }
        
        return macAddress
    }
    
    func connect(macAddress: String) async {
        await MainActor.run {
            isConnecting = true
        }
                
        if FileManager.default.fileExists(atPath: pidUrl.path()) {
            let contents = try! String.init(contentsOf: pidUrl)
            let pid = Int32(contents)!
            
            kill(pid, SIGTERM)
        }
        
        wsProcess = try! Command.init(executablePath: pythonFilePath)
            .addArgument(wsServerPath!)
            .addArgument("--mac=\(macAddress)")
            .setStdout(.pipe)
            .setStderr(.pipe)
            .spawn()

        
        do {
            try wsProcess?.identifier.description.write(to: URL(fileURLWithPath: pidUrl.path), atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
        
        monitorParentProcess()
        
        do {
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if (self.treadmill == nil) {
                        self.disconnect()
                    }
                }
            }
            
            for try await line in wsProcess!.stderr.lines {
                if (line.contains("server listening on 127.0.0.1:8765")) {
                    await MainActor.run {
                        isConnecting = false
                        treadmill = TreadmillService()
                    }
                }
            }
        } catch {
            await MainActor.run {
                isConnecting = false
            }

            disconnect()
        }
    }
    
    func disconnect() {
        wsProcess?.terminate()
        treadmill = nil
        
        if FileManager.default.fileExists(atPath: pidUrl.path()) {
            // delete file
            do {
                try FileManager.default.removeItem(atPath: pidUrl.path())
            } catch {
                print("Could not delete file, probably read-only filesystem")
            }
        }
    }
    
    private func monitorParentProcess() {
        let source = DispatchSource.makeProcessSource(identifier: ProcessInfo.processInfo.processIdentifier, eventMask: .exit, queue: DispatchQueue.global())

        source.setEventHandler {
            print("Parent process terminated. Killing child process...")
            self.wsProcess?.terminate()
            source.cancel()
        }
        
        source.resume()
    }
}
