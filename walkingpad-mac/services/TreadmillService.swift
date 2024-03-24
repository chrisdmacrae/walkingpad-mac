//
//  TreadmillService.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import Foundation
import Starscream

class TreadmillService : ObservableObject, WebSocketDelegate {
    @Published var isRunning = false
    @Published var isWSConnected = false
    @Published var currentSpeed = 0
    @Published var isBluetoothConnected = false
    @Published var stats = Stats(time: 0, distance: 0, steps: 0)
    
    private var expectedResponses: [ExpectedResponse] = []
    private var socket: WebSocket
    
    init() {
        var request = URLRequest(url: URL(string: "http://localhost:8765")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    func connect() {
        do {
            let id = randomString(length: 7)
            let event = Event(id: id, method: "connect")
            let eventData = try JSONEncoder().encode(event)
            
            if let jsonString = String(data: eventData, encoding: .utf8) {
                socket.write(string: jsonString) {
                    print("Started treadmill: \(jsonString)")
                }
                
                isBluetoothConnected = true
            }
        } catch {
            print("Failed to start treadmill")
            
            self.isBluetoothConnected = false
        }
    }
    
    func start() {
        do {
            let id = randomString(length: 7)
            let method = "run"
            let event = Event(id: id, method: method)
            let eventData = try JSONEncoder().encode(event)
            
            if let jsonString = String(data: eventData, encoding: .utf8) {
                socket.write(string: jsonString) {
                    print("Sent start treadmill: \(jsonString)")
                }
                
                expectedResponses.append(ExpectedResponse(id: id, method: method))
            }
        } catch {
            print("Failed to start treadmill")
            
            self.isRunning = false
        }
    }
    
    func stop() {
        do {
            let id = randomString(length: 7)
            let method = "stop"
            let event = Event(id: id, method: method)
            let eventData = try JSONEncoder().encode(event)
            
            if let jsonString = String(data: eventData, encoding: .utf8) {
                socket.write(string: jsonString) {
                    print("Sent stopped treadmill: \(jsonString)")
                }
                
                expectedResponses.append(ExpectedResponse(id: id, method: method))

            }
        } catch {
            print("Failed to stop treadmill")
        }
    }
    
    func getStats() {
        do {
            let id = randomString(length: 7)
            let method = "get_stats"
            let event = Event(id: id, method: method)
            let eventData = try JSONEncoder().encode(event)
            
            if let jsonString = String(data: eventData, encoding: .utf8) {
                socket.write(string: jsonString) {
                    print("Requested treadmill stats: \(jsonString)")
                }
                
                expectedResponses.append(ExpectedResponse(id: id, method: method))
            }
        } catch {
            print("Failed to request treadmill stats")
        }
    }
    
    func streamStats() async {
        while(isRunning) {
            self.getStats()
            do {
                try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
            } catch {
                // uh-oh
            }
        }
    }
    
    func increaseSpeed(increment: Int) {
        currentSpeed += increment;
        if (currentSpeed > 60) {
          currentSpeed = 60;
        }
        
        return setSpeed(speed: currentSpeed);
    }

    func decreaseSpeed(increment: Int) {
        currentSpeed -= increment;
        if (currentSpeed < 0) {
          currentSpeed = 0;
        }
      
        return setSpeed(speed: currentSpeed);
    }
    
    func setSpeed(speed: Int) {
        do {
            let id = randomString(length: 7)
            let method = "set_speed"
            let event = SpeedEvent(id: id, method: method, params: SpeedParams(speed: speed))
            let eventData = try JSONEncoder().encode(event)
            
            if let jsonString = String(data: eventData, encoding: .utf8) {
                socket.write(string: jsonString) {
                    print("Set speed to \(speed): \(jsonString)")
                }
                
                expectedResponses.append(ExpectedResponse(id: id, method: method))
            }
        } catch {
            print("Failed to set speed")
        }
    }
    
    func handleResponse(response: String) {
        if let jsonData = response.data(using: .utf8) {
            do {
                // Try to deserialize the JSON data into a Swift dictionary
                if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject] {
                    let receivedResponse = ReceivedResponse(id: String(describing: json["id"]!))
                    
                    print(receivedResponse)
                    
                    if let expectedResponse = expectedResponses.first(where: { res in
                        res.id == receivedResponse.id
                    }) {
                        print(expectedResponse)
                        switch (expectedResponse.method) {
                        case "run":
                            self.isRunning = true
                            self.currentSpeed = 20
                        case "stop":
                            self.isRunning = false
                            self.currentSpeed = 0
                        case "get_stats":
                            let response = StatsResponse(time: json["result"]?["time"] as! Double, dist: json["result"]?["dist"] as! Double, steps: json["result"]?["steps"] as! Int, state: json["result"]?["state"] as! Int)
                            
                            self.stats = Stats(time: response.time, distance: response.dist, steps: response.steps)
                            if (response.state == 0 && stats.time > 0) {
                                self.isRunning = false
                            }
                        case "set_speed":
                            print(json)
                        default:
                            print("Received an unhandled response: \(expectedResponse)")
                        }
                    }
                }
            } catch {
                print("Error parsing respons: \(response)\nError: \(error)")
            }
        }
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            isWSConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isWSConnected = false
            isBluetoothConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            handleResponse(response: string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isWSConnected = false
            isBluetoothConnected = false
        case .error(let error):
            isWSConnected = false
            isBluetoothConnected = false
            print(error)
            case .peerClosed:
                   break
        }
    }
}

struct ReceivedResponse {
    var id: String
    var result: String?
}

struct StatsResponse {
    var time: Double
    var dist: Double
    var steps: Int
    var state: Int
}

struct Stats {
    var time: Double
    var distance: Double
    var steps: Int
}

struct ExpectedResponse {
    var id: String
    var method: String
}

struct Event : Encodable {
    var id: String
    var method: String
    var params: String? = nil
}

struct SpeedEvent : Encodable {
    var id: String
    var method: String
    var params: SpeedParams
}

class SpeedParams : Encodable {
    var speed: Int
    
    init(speed: Int) {
        self.speed = speed
    }
}

func randomString(length: Int) -> String {
    let characters = "0123456789"
    var randomString = ""

    for _ in 0..<length {
        let randomNum = Int(arc4random_uniform(UInt32(characters.count)))
        let randomIndex = characters.index(characters.startIndex, offsetBy: randomNum)
        let randomCharacter = characters[randomIndex]
        randomString.append(randomCharacter)
    }

    return randomString
}

