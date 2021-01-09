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
        //TODO: Fix Effect usage. Somehow does not work with AF
        //Effect.future { callback in
            AF.request("\(api)/left", method: .post)
                .validate(statusCode: 200..<300)
                .response { response in
                    debugPrint(response)
                    switch response.result {
                        case .success:
                            print("Validation Successful")
                            //callback(.success(Void()))
                        case let .failure(error):
                            print(error)
                            //callback(.failure(Failure()))
                        }
                }
        //}
        
        return Effect.future { callback in
            callback(.failure(Failure()))
        }
        
        /*Effect.future { (callback) in
            AF.request("\(api)/left", method: .post)
                .validate(statusCode: 200..<300)
                .response { response in
                    debugPrint(response)
                    switch response.result {
                        case .success:
                            print("Validation Successful")
                            callback(.success(Void()))
                        case let .failure(error):
                            print(error)
                            //callback(.failure(error))
                        }
                }
        }*/
    },
    right: {
        Effect.future { (callback) in
            AF.request("\(api)/right", method: .post)
                .response { response in
                    debugPrint(response)
                    /*if response {
                        callback(.success(WishListResponse(data: results)))
                    } else {
                        callback(.failure(.requestFailure))
                    }*/
                }
        }
    })
}
