import Foundation
import ComposableArchitecture
import Combine

let wsApi = "ws://raspberrypi.local:3002"

private var socketUpdatesSubscribers:
  [AnyHashable: Effect<String, Error>.Subscriber] =
    [:]

struct ApiClient {
    static var socket = WebSocketConnector(withSocketURL: URL(string: wsApi)!) {
        didSet {
            socket.didReceiveMessage = { message in
                print(message)
            }
        }
    }
    
    var connect: () -> Effect<String, Error>
    var disconnect: () -> Effect<Never, Never>
    var angle: (_: Float) -> Effect<Never, Never>
    var speed: (_: Float) -> Effect<Never, Never>

    struct Failure: Error, Equatable {}
}

// MARK: - Live API implementation
extension ApiClient {
    static let live = ApiClient(
    connect: {
        Effect.run { subscriber in
            guard socketUpdatesSubscribers[1] == nil
            else { return AnyCancellable {} }
            
            socketUpdatesSubscribers[1] = subscriber
            socket.didOpenConnection = {
                print("Connection opened")
                subscriber.send(.init("success"))
            }
            socket.didReceiveError = { error in
                print(error)
                subscriber.send(completion: .failure(error))
            }
            
            socket.establishConnection()
            
            return AnyCancellable {
                socket.disconnect()
            }
        }
    },
    disconnect: {
        Effect.run { subscriber in
            socket.didCloseConnection = {
                print("Connection closed")
                //TODO
            }
            socket.didReceiveError = { error in
                print(error)
                //TODO
                //subscriber.send(completion: .failure(error))
            }
            
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
