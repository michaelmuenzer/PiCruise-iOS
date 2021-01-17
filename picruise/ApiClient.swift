import Foundation
import Alamofire
import ComposableArchitecture

let wsApi = "ws://raspberrypi.local:3002"

struct ApiClient {
    static let socket = WebSocketConnector(withSocketURL: URL(string: wsApi)!)
    
    var connect: () -> Effect<Void, Failure>
    var disconnect: () -> Effect<Void, Failure>
    var angle: (_: Float) -> Effect<Void, Failure>
    var speed: (_: Float) -> Effect<Void, Failure>

    struct Failure: Error, Equatable {}
}

// MARK: - Live API implementation
extension ApiClient {
    static let live = ApiClient(
    connect: {
        socket.establishConnection()
                
        socket.didReceiveMessage = { message in
            //print(message)
        }
        
        socket.didReceiveError = { error in
            //Handle error here
        }
        
        socket.didOpenConnection = {
            print("Connection opened")
        }
        
        socket.didCloseConnection = {
            // Connection closed
        }
        
        return Effect.future { callback in
            callback(.failure(Failure()))
        }
    },
    disconnect: {
        socket.disconnect()
        
        return Effect.future { callback in
                callback(.failure(Failure()))
        }
    },
    angle: { normalizedAngle in
        socket.send(message: "angle: \(NSString(format: "%.2f", normalizedAngle))")
        
        return Effect.future { callback in
                callback(.failure(Failure()))
        }
    },
    speed: { normalizedSpeed in
        socket.send(message: "speed: \(NSString(format: "%.2f", normalizedSpeed))")
        
        return Effect.future { callback in
                callback(.failure(Failure()))
        }
    })
}
