import Foundation

public class Flame {
  let pathHandler: PathHandler = PathHandler()
  public init() {}
}

extension Flame {
  
  public func start(port: Int, _ callback: ((_ result: Result<Void>) -> ())?) {
    let server = HTTPServer(delegate: self)
    
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
    let handlers = self.handlers(with: request.path, for: request.method)
    guard handlers.count > 0 else {
      response.send(status: 404)
      return
    }
    handlers.forEach { handler in
      handler(request, response)
    }
  }
}
