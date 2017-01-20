//
//  RequestHandler.swift
//  Blackfire
//
//  Created by Elliott Minns on 20/01/2017.
//
//

import Foundation

struct RequestHandler {
  let nodes: [Node]
  
  init(nodes: [Node]) {
    self.nodes = nodes
  }
  
  func handle(request: HTTPRequest, response: HTTPResponse) {
    let handlers = nodes.last?.handlers[request.method] ?? []

    guard handlers.count > 0 else {
      response.send(status: 404)
      return
    }
    /*
    let comps = request.path.components(separatedBy: "/")
    let params = self.nodes.reduce((0, [:])) { (result, node) -> (Int, [String: String]) in
      if !node.path.isEmpty && node.path[node.path.startIndex] == ":" {
        let key = node.path.substring(from: node.path.index(after: node.path.startIndex))
        let value = comps[result.0]
        return (result.0 + 1, [key: value])
      } else {
        return (result.0 + 1, result.1)
      }
    }.1
    */
    let params: [String: String] = [:]
    let request = Request(params: params, raw: request)
    handlers.forEach { handler in
      handler(request, response)
    }
  }
}
