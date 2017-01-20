//
//  Request.swift
//  Blackfire
//
//  Created by Elliott Minns on 20/01/2017.
//
//

import Foundation

public class Request: HTTPRequest {
  public let params: [String: String]
  
  init(params: [String: String], raw: HTTPRequest) {
    self.params = params
    super.init(headers: raw.headers, method: raw.method,
               body: raw.body, path: raw.path, httpProtocol: raw.httpProtocol)
  }
}
