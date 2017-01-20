public typealias Response = HTTPResponse
public typealias RouteHandler = (Request, Response) -> ()

public protocol Routing {
  func use(_ path: String, _ handler: @escaping RouteHandler)
  func get(_ path: String, _ handler: @escaping RouteHandler)
  func post(_ path: String, _ handler: @escaping RouteHandler)
  func put(_ path: String, _ handler: @escaping RouteHandler)
  func delete(_ path: String, _ handler: @escaping RouteHandler)
  func use(_ path: String, _ handler: Routing)
}

public protocol PathRouting: Routing {
  var pathHandler: PathHandler { get }
}

extension PathRouting {

  func handler(for path: String) -> RequestHandler {
    let nodes = pathHandler.nodes(for: path)
    return RequestHandler(nodes: nodes)
  }
  
  public func use(_ path: String, _ handler: @escaping RouteHandler) {
    pathHandler.use(path, handler)
  }
  
  public func get(_ path: String, _ handler: @escaping RouteHandler) {
    pathHandler.get(path, handler)
  }
  
  public func post(_ path: String, _ handler: @escaping RouteHandler) {
    pathHandler.post(path, handler)
  }
  
  public func put(_ path: String, _ handler: @escaping RouteHandler) {
    pathHandler.put(path, handler)
  }
  
  public func delete(_ path: String, _ handler: @escaping RouteHandler) {
    pathHandler.delete(path, handler)
  }
  
  public func use(_ path: String, _ handler: Routing) {
    pathHandler.use(path, handler)
  }
  
}
