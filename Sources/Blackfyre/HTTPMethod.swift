
import Foundation

public enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case patch = "PATCH"
  case unknown = "UNKNOWN"
}

extension HTTPMethod {
  
  init?(string: String) {
    if let method = HTTPMethod.init(rawValue: string) {
      self = method
    } else {
      return nil
    }
  }
}
