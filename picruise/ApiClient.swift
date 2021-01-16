import Foundation
import Alamofire
import ComposableArchitecture
import Starscream

let api = "http://raspberrypi.local:8082"
let wsApi = "http://raspberrypi.local:3002"

struct ApiClient {
    var connect: () -> Effect<Void, Failure>
    var disconnect: () -> Effect<Void, Failure>
    var left: () -> Effect<Void, Failure>
    var right: () -> Effect<Void, Failure>

    struct Failure: Error, Equatable {}
}

// MARK: - Live API implementation
extension ApiClient {
    static let live = ApiClient(
    connect: {
        /*var request = URLRequest(url: URL(string: wsApi)!)
        request.timeoutInterval = 5
        
        var socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()*/
        
        Effect.future { callback in
            AF.request("\(api)/left", method: .post)
                .validate(statusCode: 200..<300)
                .response { response in
                    //debugPrint(response)
                    switch response.result {
                        case .success:
                            //print("Request Successful")
                            callback(.success(Void()))
                        case let .failure(error):
                            //print(error)
                            callback(.failure(Failure()))
                        }
                }
        }
    },
    disconnect: {
        //socket.disconnect()
        
        Effect.future { callback in
            AF.request("\(api)/left", method: .post)
                .validate(statusCode: 200..<300)
                .response { response in
                    //debugPrint(response)
                    switch response.result {
                        case .success:
                            //print("Request Successful")
                            callback(.success(Void()))
                        case let .failure(error):
                            //print(error)
                            callback(.failure(Failure()))
                        }
                }
        }
    },
    left: {
        //socket.write(string: "angle: \(distance)")
        Effect.future { callback in
            AF.request("\(api)/left", method: .post)
                .validate(statusCode: 200..<300)
                .response { response in
                    //debugPrint(response)
                    switch response.result {
                        case .success:
                            //print("Request Successful")
                            callback(.success(Void()))
                        case let .failure(error):
                            //print(error)
                            callback(.failure(Failure()))
                        }
                }
        }
    },
    right: {
        //socket.write(string: "speed: \(distance)")
        Effect.future { (callback) in
            AF.request("\(api)/right", method: .post)
                .validate(statusCode: 200..<300)
                .response { response in
                    //debugPrint(response)
                    switch response.result {
                        case .success:
                            //print("Request Successful")
                            callback(.success(Void()))
                        case let .failure(error):
                            //print(error)
                            callback(.failure(Failure()))
                        }
                }
        }
    })
}
