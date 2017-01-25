import Foundation

public class HTTPResponse {
  
  let connection: Connection
  
  public var status: Int
  
  public var headers: [String: String]
  
  var body: Buffer {
    didSet {
      if body.size > 0 {
        self.headers["Content-Length"] = "\(body.size)"
      }
    }
  }
  
  init(connection: Connection) {
    self.connection = connection
    self.status = 200
    self.headers = [:]
    self.body = Buffer(size: 0)
  }
  
  func send() {
    let status = HTTPStatus(status: self.status)
    var http = "HTTP/1.1 \(status.stringValue)\r\n"
    for (key, value) in headers {
      http += "\(key): \(value)\r\n"
    }
    http += "\r\n"
    http += self.body.toString()
    connection.write(http)
  }
  
  public func send(status: Int) {
    self.status = status
    self.send()
  }
  
  public func send(text: String) {
    self.headers["Content-Type"] = "text/plain"
    self.body = Buffer(string: text)
    send()
  }
  
  public func send(html: String) {
    self.headers["Content-Type"] = "text/html"
    self.body = Buffer(string: html)
    send()
  }
  
  public func send(json: Any) {
    self.headers["Content-Type"] = "application/json"
    do {
      if JSONSerialization.isValidJSONObject(json) {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        self.body = Buffer(data: data)
      } else {
        self.status = 500
      }
    } catch {
      self.status = 500
    }
    send()
  }
  
  public func send(data: Data) {
    connection.write(data: data)
  }
  
  public func send(error: String) {
    status = 500
    self.body = Buffer(string: error)
    self.send()
  }
  
  
}
