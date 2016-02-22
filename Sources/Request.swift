import Foundation
import Vaquita

public class Request {

    public enum Method: String {
        case Get = "GET"
        case Post = "POST"
        case Put = "PUT"
        case Patch = "PATCH"
        case Delete = "DELETE"
        case Unknown = "x"
    }

    public let method: Method

    public var params: [String: String] {
        get {
            return parameters
        }

        set {
            parameters = newValue;
        }
    }

    public var parameters: [String: String] = [:]

    ///GET or POST data
    public var data: [String: Any] = [:]

    public var cookies: [String: String] = [:]

    public var path: String = ""

    var headers: [String: String] = [:]

    public var body: Data = Data(bytes: [])

    public var address: String? = ""

    public var files: [String: [MultipartFile]] = [:]

    public var session: Session = Session()

    init(method: Method) {
        self.method = method
    }

    public func getHeader(header: String) -> String? {
        return headers[header]
    }

    public func setValue(value: String, forHeader header: String) {
        headers[header] = value
    }
}
