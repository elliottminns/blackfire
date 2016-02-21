import Foundation

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

    public var parameters: [String: String] = [:]
    
    ///GET or POST data
    public var data: [String: Any] = [:]

    public var cookies: [String: String] = [:]

    public var path: String = ""

    var headers: [String: String] = [:]

    var body: [UInt8] = []

    var address: String? = ""

    public var files: [String: [MultipartFile]] = [:]

    public var session: Session = Session()

    init(method: Method) {
        self.method = method
    }

    func parseUrlencodedForm() -> [(String, String)] {
        guard let contentTypeHeader = headers["content-type"] else { return [] }

        let contentTypeHeaderTokens = contentTypeHeader.split(";").map { $0.trim() }

        guard let contentType = contentTypeHeaderTokens.first where contentType == "application/x-www-form-urlencoded" else { return [] }

        return String.fromUInt8(body).split("&").map { (param: String) -> (String, String) in
            let tokens = param.split("=")
            if let name = tokens.first, value = tokens.last where tokens.count == 2 {
                return (name.replace("+", new: " ").removePercentEncoding(),
                        value.replace("+", new: " ").removePercentEncoding())
            }
            return ("","")
        }
    }
}
