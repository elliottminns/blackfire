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
  let base: Node = Node(path: "")
  
  private func comps(for path: String) -> [String] {
    let chars = CharacterSet(charactersIn: "/")
    let trimmed = path.trimmingCharacters(in: chars)
    return trimmed.isEmpty ? [] : trimmed.components(separatedBy: "/")
  }
  
  private func node(for path: String) -> Node {
    let comps = self.comps(for: path)
    return comps.reduce(base) { (node, path) in
      let next: Node
      if let child = node.children[path] {
        next = child
      } else {
        next = Node(path: path)
        node.children[path] = next
      }
      return next
    }
  }
  
  func add(handler: @escaping RouteHandler, for path: String, with method: HTTPMethod) {
    let node = self.node(for: path)
    let handlers = (node.handlers[method] ?? []) + [handler]
    node.handlers[method] = handlers
  }
  
  func add(child: Node, for path: String) {
    var comps = path.components(separatedBy: "/")
    let last = comps.popLast() ?? ""
    let node = self.node(for: comps.joined(separator: "/"))
    node.children[last] = child
  }
  
  func handlers(for path: String, with method: HTTPMethod) -> [RouteHandler] {
    let comps = self.comps(for: path)
    
    let node = comps.reduce(base) { (node, path) -> Node? in
      return node?.children[path]
    }

    return node?.handlers[method] ?? []
  }
}


extension PathHandler: Routing {

  func use(_ path: String, _ handler: Routing) {
    if let pathRouting = handler as? PathRouting {
      add(child: pathRouting.pathHandler.base, for: path)
    }
  }
  
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
