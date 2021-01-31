import Foundation
import ComposableArchitecture
import Combine

let wsApi = "ws://raspberrypi.local:3002"

private var socketUpdatesSubscriber: Effect<String, Error>.Subscriber?

struct ApiClient {
    static var socket = WebSocketConnector(withSocketURL: URL(string: wsApi)!)
    
    var connect: () -> Effect<String, Error>
    var disconnect: () -> Effect<String, Error>
    var angle: (_: Float) -> Effect<Never, Never>
    var speed: (_: Float) -> Effect<Never, Never>

    struct Failure: Error, Equatable {}
}

// MARK: - Live API implementation
extension ApiClient {
    static let live = ApiClient(
    connect: {
        Effect.run { subscriber in
            if socketUpdatesSubscriber == nil {
                socketUpdatesSubscriber = subscriber
            }

            socket.didOpenConnection = {
                print("Connection opened")
                socket.send(message: "start")
                subscriber.send(.init("success"))
            }
            
            socket.didReceiveError = { error in
                print(error)
                subscriber.send(completion: .failure(error))
            }
            
            socket.establishConnection()
            return AnyCancellable {}
        }
    },
    disconnect: {
        Effect.run { subscriber in
            guard socketUpdatesSubscriber != nil
            else { return AnyCancellable {} }

            socket.didCloseConnection = {
                print("Connection closed")
                subscriber.send(.init("success"))
                
                // Reset web-socket, connection established, but not connected
                socket = WebSocketConnector(withSocketURL: URL(string: wsApi)!)
            }
            socket.didReceiveError = { error in
                print(error)
                subscriber.send(completion: .failure(error))
            }
            
            socket.send(message: "stop")
            socket.disconnect()
            return AnyCancellable {}
        }
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
