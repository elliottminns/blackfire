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

public class PathHandler {
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
        if (!path.isEmpty && path[path.startIndex] == ":") {
          node.children[":*"] = next
        } else {
          node.children[path] = next
        }
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
  
  func nodes(for path: String) -> [Node] {
    let comps = self.comps(for: path)
    let begin: [Node?] = [base]
    let nodes = comps.reduce(begin) { (nodes, path) -> [Node?] in
      guard let last = nodes.last else { return [] }
      
      if let child = last?.children[path] {
        return nodes + [child]
      } else {
        return nodes + [last?.children[":*"]]
      }
    }

    return nodes.flatMap { $0 }
  }
}


extension PathHandler: Routing {

  public func use(_ path: String, _ handler: Routing) {
    if let pathRouting = handler as? PathRouting {
      add(child: pathRouting.pathHandler.base, for: path)
    }
  }
  
  public func use(_ path: String, _ handler: @escaping RouteHandler) {
    let methods: [HTTPMethod] = [.get, .post, .put, .delete]
    methods.forEach { method in
      add(handler: handler, for: path, with: method)
    }
  }
  
  public func get(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .get)
  }
  
  public func post(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .post)
  }
  
  public func put(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .put)
  }
  
  public func delete(_ path: String, _ handler: @escaping RouteHandler) {
    add(handler: handler, for: path, with: .delete)
  }
}
