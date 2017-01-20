import Foundation

public enum FlameType {
  case serial
  case concurrent
}

extension FlameType {
  var queueType: QueueType {
    switch self {
    case .serial:
      return QueueType.serial
    case .concurrent:
      return QueueType.concurrent
    }
  }
}

public class Flame {
  public let pathHandler: PathHandler = PathHandler()
  
  public let type: FlameType
  
  public init(type: FlameType = .serial) {
      self.type = type
  }
}

extension Flame {
  
  public func start(port: Int, _ callback: ((_ result: Result<Void>) -> ())?) {
    let server = HTTPServer(delegate: self, type: self.type.queueType)
    
    do {
      try server.listen(port: port)
      callback?(Result.success())
      RunLoop.main.run()
    } catch {
      callback?(Result.failure(error))
    }
  }
}

extension Flame: PathRouting {
  
}

extension Flame: HTTPServerDelegate {
  func server(_ server: HTTPServer, didReceive request: HTTPRequest,
              response: HTTPResponse) {
    let handler = self.handler(for: request.path)
    handler.handle(request: request, response: response)
  }
}
