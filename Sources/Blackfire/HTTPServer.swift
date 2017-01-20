
import Foundation

protocol HTTPServerDelegate {
  func server(_ server: HTTPServer, didReceive request: HTTPRequest,
              response: HTTPResponse)
}

enum QueueType {
  case serial
  case concurrent
}

extension QueueType {
  func dispatchQueue() -> DispatchQueue {
    switch self {
    case .concurrent:
      return DispatchQueue.global()
    case .serial:
      return DispatchQueue.main
    }
  }
}

class HTTPServer {
  
  public var port: Int {
    return currentPort
  }
  
  var currentPort: Int
  
  var server: Server?
  
  var delegate: HTTPServerDelegate?
  
  let queueType: QueueType
  
  
  init(type: QueueType) {
    currentPort = 80
    self.delegate = nil
    self.queueType = type
  }
  
  init(delegate: HTTPServerDelegate, type: QueueType) {
    currentPort = 80
    self.delegate = delegate
    self.queueType = type
  }
  
  func listen(port: Int) throws {
    self.currentPort = port
    if server == nil {
      server = try Server(port: port, delegate: self, type: .tcp, queueType: self.queueType)
      try server?.listen()
    }
  }
  
  func sendErrorResponse(toConnection connection: Connection) {
    let response = "HTTP/1.1 400 Client Error"
    connection.write(response)
  }
  
}

extension HTTPServer: ServerDelegate {
  
  public func server(_ server: Server, didCreateConnection connection: Connection) {
    
    var data = Data()
    
    connection.read { buffer, amount in
      
      data.append(buffer.buffer, length: amount)
      
      do {
        guard let request = try HTTPParser(data: data).parse() else { return }
        request.connection = connection
        
        let response = HTTPResponse(connection: connection)
        self.delegate?.server(self, didReceive: request,
                              response: response)
      } catch {
        //                if let error = error as? ParserError {
        //                    print(error.message)
        //                    print(error.problemArea)
        //                }
        //                self.sendErrorResponse(toConnection: connection)
      }
    }
  }
}
