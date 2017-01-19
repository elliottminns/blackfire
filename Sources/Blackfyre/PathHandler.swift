import Foundation

class Node {
  let path: String
  var handlers: [HTTPMethod: [RouteHandler]]
  var children: [String: Node]
  
  init(path: String) {
    self.path = path
    handlers = [:]
    children = [:]
  }
}

class PathHandler {
  let base: Node = Node(path: "/")
  
  func add(handler: @escaping RouteHandler, for path: String, with method: HTTPMethod) {
    let comps = path.components(separatedBy: "/")
    
    let node = comps.reduce(base) { (node, path) in
      let next: Node
      if let child = node.children[path] {
        next = child
      } else {
        next = Node(path: path)
        node.children[path] = next
      }
      return next
    }
    
    let handlers = (node.handlers[method] ?? []) + [handler]
    node.handlers[method] = handlers
  }
  
  func handlers(for path: String, with method: HTTPMethod) -> [RouteHandler] {
    let chars = CharacterSet(charactersIn: "/")
    let comps = [""] + path.trimmingCharacters(in: chars)
      .components(separatedBy: "/")
    
    let node = comps.reduce(base) { (node, path) -> Node? in
      return node?.children[path]
    }

    return node?.handlers[method] ?? []
  }
}



extension PathHandler: Routing {

  func use(_ path: String, _ handler: @escaping RouteHandler) {
    let methods: [HTTPMethod] = [.get, .post, .put, .delete]
    methods.forEach { method in
      add(handler: handler, for: path, with: method)
    }
  }
  
  func get(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .get)
  }
  
  func post(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .post)
  }
  
  func put(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .put)
  }
  
  func delete(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .delete)
  }
}
