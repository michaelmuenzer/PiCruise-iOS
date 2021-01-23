import Foundation
import Alamofire
import ComposableArchitecture

let wsApi = "ws://raspberrypi.local:3002"

struct ApiClient {
    static var socket = WebSocketConnector(withSocketURL: URL(string: wsApi)!) {
        didSet {
            socket.didReceiveMessage = { message in
                //print(message)
            }
            
            socket.didReceiveError = { error in
                print(error)
            }
            
            socket.didOpenConnection = {
                print("Connection opened")
                //store.send(.connectResponse(.failure))
            }
            
            socket.didCloseConnection = {
                print("Connection closed")
            }
        }
    }
    
    var connect: () -> Effect<Never, Never>
    var disconnect: () -> Effect<Never, Never>
    var angle: (_: Float) -> Effect<Never, Never>
    var speed: (_: Float) -> Effect<Never, Never>

    struct Failure: Error, Equatable {}
}

// MARK: - Live API implementation
extension ApiClient {
    static let live = ApiClient(
    connect: {
        socket.establishConnection()
        return Effect.none
    },
    disconnect: {
        socket.disconnect()
        return Effect.none
    },
    angle: { normalizedAngle in
        socket.send(message: "angle: \(NSString(format: "%.2f", normalizedAngle))")
        return Effect.none
    },
    speed: { normalizedSpeed in
        socket.send(message: "speed: \(NSString(format: "%.2f", normalizedSpeed))")
        return Effect.none
    })
}
