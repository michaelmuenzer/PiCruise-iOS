import Foundation
import Alamofire
import ComposableArchitecture

let api = "http://raspberrypi.local:8082"

struct ApiClient {
  var left: () -> Effect<Void, Failure>
  var right: () -> Effect<Void, Failure>

  struct Failure: Error, Equatable {}
}

// MARK: - Live API implementation
extension ApiClient {
  static let live = ApiClient(
    left: {
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
