import Foundation

protocol WebSocketProtocol {
    func send(message : String)
    func send(data : Data)
    func establishConnection()
    func disconnect()
}

class WebSocketConnector : NSObject {
    var didOpenConnection : (()->())?
    var didCloseConnection : (()->())?
    var didReceiveMessage : ((_ message : String)->())?
    var didReceiveData : ((_ message : Data)->())?
    var didReceiveError : ((_ error : Error)->())?

    var urlSession : URLSession!
    var operationQueue : OperationQueue = OperationQueue()
    var socket : URLSessionWebSocketTask!
    
    init(withSocketURL url : URL){
        super.init()
        
        urlSession  = URLSession(configuration: .default, delegate: self, delegateQueue: operationQueue)
        socket = urlSession.webSocketTask(with: url)
    }
    
    private func addListener(){
        socket.receive {[weak self] (result) in
            switch result {
                case .success(let response):
                    switch response {
                        case .data(let data):
                            self?.didReceiveData?(data)
                        case .string(let message):
                            self?.didReceiveMessage?(message)
                        default:
                            fatalError()
                    }
                case .failure(let error):
                    self?.didReceiveError?(error)
            }

            self?.addListener()
        }
    }
}

extension WebSocketConnector : WebSocketProtocol {
    
    func establishConnection(){
        socket.resume()
        addListener()
    }
    
    func disconnect(){
        socket.cancel(with: .goingAway, reason: nil)
    }
    
    func send(message: String) {
        socket.send(URLSessionWebSocketTask.Message.string(message)) {[weak self] (error) in
            if let error = error {
                self?.didReceiveError?(error)
            }
        }
    }
    
    func send(data: Data) {
        socket.send(URLSessionWebSocketTask.Message.data(data)) {[weak self] (error) in
            if let error = error {
                self?.didReceiveError?(error)
            }
        }
    }
}

extension WebSocketConnector : URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        didOpenConnection?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        didCloseConnection?()
    }
}
