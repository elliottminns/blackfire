//
//  Request.swift
//  Blackfire
//
//  Created by Elliott Minns on 20/01/2017.
//
//

import Foundation

public class Request {
  public let params: [String: String]
  
  let raw: HTTPRequest
  
  public var query: [String: Any] {
    return raw.query
  }
  
  public var path: String {
    return raw.path
  }
  
  public var headers: [String: String] {
    return raw.headers
  }
  
  public var method: HTTPMethod {
    return raw.method
  }
  
  public var body: String {
    return raw.body
  }
  
  public var httpProtocol: String {
    return raw.httpProtocol
  }
  
  init(params: [String: String], raw: HTTPRequest) {
    self.params = params
    self.raw = raw
  }
  
}
