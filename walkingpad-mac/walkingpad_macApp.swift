//
//  walkingpad_macApp.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-22.
//

import CoreBluetooth
import MenuBarExtraAccess
import SwiftData
import SwiftUI
import TreadmillController

class Treadmill: TreadmillControllerDelegate, ObservableObject {
  @Published var isScanning = false
  @Published var isConnected = false

  @Published var isRunning = false

  @Published var stats: TreadmillStats? = nil

  @Published var desiredSpeed: Double = 1

  public let treadmillController = TreadmillController()

  init() {
    treadmillController.delegate = self
  }

  func treadmillController(
    _ treadmillController: TreadmillController, didUpdateStats stats: TreadmillStats
  ) {
    print("Got Status", stats)
    DispatchQueue.main.async {
      self.stats = stats
    }
  }

  // standby = beltState 5 and mode 2
  // manual = beltState 0 and mode 1
  // running = beltState 9 or 1 and mode 1

  func setDesiredSpeed(_ speed: Double) {
    DispatchQueue.main.async {
      self.desiredSpeed = min(max(0.5, speed), 6.0)
      self.treadmillController.setSpeed(self.desiredSpeed)
    }
  }

  func treadmillController(
    _ treadmillController: TreadmillController, beltSpeedChanged stats: TreadmillStats
  ) {
    print("Belt Speed Changed", stats.beltSpeed)

  }

  func treadmillController(
    _ treadmillController: TreadmillController, beltStarted stats: TreadmillStats
  ) {
    print("Belt Started", stats.beltState)
    DispatchQueue.main.async {
      self.isRunning = true
    }
  }

  func treadmillController(
    _ treadmillController: TreadmillController, beltStopped stats: TreadmillStats
  ) {
    print("Belt Stopped", stats.beltState)
    DispatchQueue.main.async {
      self.isRunning = false
    }
  }

  func treadmillController(
    _ treadmillController: TreadmillController, modeChanged stats: TreadmillStats
  ) {
    print("Mode Changed", stats.beltMode)
  }

  func treadmillController(
    _ treadmillController: TreadmillController, readyToScanForTreadmills ready: Bool
  ) {
    print("Starting Scanning")
    treadmillController.startScanning()

    DispatchQueue.main.async {
      self.isScanning = true
    }
  }

  func treadmillController(
    _ treadmillController: TreadmillController, didDiscoverTreadmill peripheral: CBPeripheral
  ) {
    print("Stopping Scanning")
    treadmillController.stopScanning()

    DispatchQueue.main.async {
      self.isScanning = false
      self.isConnected = true
    }

    print("Starting connecting")
    treadmillController.connectToTreadmill(peripheral)
  }

  func treadmillController(
    _ treadmillController: TreadmillController, didConnectToTreadmill peripheral: CBPeripheral
  ) {
    print("Is connected")

    treadmillController.setStatsRequestInterval(3)
    treadmillController.startRequestingStats()

    DispatchQueue.main.async {
      self.isConnected = true
    }
  }

  func treadmillController(
    _ treadmillController: TreadmillController,
    didFailToConnectToTreadmill peripheral: CBPeripheral, error: any Error
  ) {
    print("Failed to connected to treadmill")
  }

  func treadmillController(
    _ treadmillController: TreadmillController, didDisconnectFromTreadmill peripheral: CBPeripheral,
    error: any Error
  ) {
    print("Disconnected to treadmill")
  }

}

@main
struct walkingpad_macApp: App {
  @ObservedObject private var treadmill = Treadmill()
  @State var isMenuPresented: Bool = false
  @State var menuType = AppMenuType.control

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Session.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    MenuBarExtra("WalkingPad") {
      ContentView(menuType: $menuType, treadmill: treadmill)
        .modelContainer(sharedModelContainer)
    }
    .menuBarExtraStyle(.window)
    .menuBarExtraAccess(isPresented: $isMenuPresented) { statusItem in
      NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
        if event.window == statusItem.button?.window {
          menuType = AppMenuType.control
        }

        return event
      }

      NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
        if event.window == statusItem.button?.window {
          menuType = AppMenuType.context
        }

        isMenuPresented = true

        return event
      }
    }

    Settings {
      SettingsView()
        .frame(minWidth: 720, minHeight: 480)
    }
    .windowResizability(.contentSize)
  }
}

enum AppMenuType {
  case control
  case context
}
