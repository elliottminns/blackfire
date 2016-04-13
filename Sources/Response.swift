import Echo
import Foundation

public protocol Responder: class {
    func send(response: Response)
}

public protocol RendererSupplier: class {
    func rendererForFile(filename: String) -> Renderer?
}

/**
    Responses are objects responsible for returning
    data to the HTTP request such as the body, status
    code and headers.
 */
public class Response {

    public enum SerializationError: ErrorProtocol {
        case InvalidObject
        case NotSupported
    }

    public var contentType: ContentType
    public var status: Status
    public var body: [UInt8]
    public var cookies: [String: String] = [:]
    public var additionalHeaders: [String: String] = [:]

    weak var request: Request?
    unowned let responder: Responder
    weak var renderSupplier: RendererSupplier?

    let connection: Connection

    public enum ContentType {
        case Text
        case HTML
        case JSON
        case None
        case File(ext: String)
    }

    public enum Status {
        case OK, Created, Accepted, NoContent
        case MovedPermanently
        case BadRequest, Unauthorized, Forbidden, NotFound
        case Error
        case Unknown
        case Custom(Int, String)

        public var code: Int {
            switch self {
                case .OK: return 200
                case .Created: return 201
                case .Accepted: return 202
                case .NoContent: return 204

                case .MovedPermanently: return 301

                case .BadRequest: return 400
                case .Unauthorized: return 401
                case .Forbidden: return 403
                case .NotFound: return 404

                case .Error: return 500

                case .Unknown: return 0
                case .Custom(let code, _):
                    return code
            }
        }
        
        public var description: String {
            switch self {
            case .OK:
                return "OK"
            case .Created:
                return "Created"
            case .Accepted:
                return "Accepted"
            case .NoContent:
                return "No Content"
            case .MovedPermanently:
                return "Moved Permanently"
            case .BadRequest:
                return "Bad Request"
            case .Unauthorized:
                return "Unauthorized"
            case .Forbidden:
                return "Forbidden"
            case .NotFound:
                return "Not Found"
            case .Error:
                return "Internal Server Error"
            case .Unknown:
                return "Unknown"
            case .Custom(_, let description):
                return description
            }
        }
    }

    func headers() -> [String: String] {
        var headers = ["Server" : "Blackfish \(BlackfishApp.VERSION)"]

        if self.cookies.count > 0 {
            var cookieString = ""
            for (key, value) in self.cookies {
                if cookieString != "" {
                    cookieString += ";"
                }

                cookieString += "\(key)=\(value)"
            }
            headers["Set-Cookie"] = cookieString
        }

        switch self.contentType {
        case .JSON:
            headers["Content-Type"] = "application/json"
        case .HTML:
            headers["Content-Type"] = "text/html"
        case .File(let ext):
            headers["Content-Type"] = mimeMap[ext]
        default:
            break
        }

        for (key, value) in additionalHeaders {
            headers[key] = value
        }

        return headers
    }

    init(request: Request, responder: Responder, connection: Connection) {
        self.request = request
        self.status = .OK
        self.contentType = .Text
        self.body = []
        self.responder = responder
        self.connection = connection
    }
}

// MARK: - Public Methods

extension Response {

    public func send(_ status: Status? = nil) {
        if let status = status {
            self.status = status
        }
        responder.send(response: self)
    }

    public func send(text: String, status: Status = .OK) {
        body = [UInt8](text.utf8)
        contentType = .Text
        send(status)
    }

    public func send(error: String) {

        let text = "{\n\t\"error\": true,\n\t\"message\":\"\(error)\"\n}"
        body = [UInt8](text.utf8)
        contentType = .JSON
        send(.Error)
    }

    public func send(html: String, status: Status = .OK) {

        let serialised = "<html><meta charset=\"UTF-8\"><body>\(html)</body></html>"
        body = [UInt8](serialised.utf8)
        contentType = .HTML
        send(status)
    }

    public func redirect(path: String) {
        additionalHeaders["Location"] = path
        send(.MovedPermanently)
    }

    public func send(json: Any, status: Status = .OK) {
        
        let data: [UInt8]
        
        if let json = json as? AnyObject {
            if NSJSONSerialization.isValidJSONObject(json) {
                
                do {

#if os(Linux)
                    let json = try NSJSONSerialization.dataWithJSONObject(json, 
                            options: .PrettyPrinted)
#else
                    let json = try NSJSONSerialization.data(withJSONObject: json,
                            options: .prettyPrinted)
#endif
                    data = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(json.bytes), count: json.length))
                } catch let errorMessage {
                    self.send(error: "Server error: \(errorMessage)")
                    return
                }
            } else {
                self.send(error: "Server error: Invalid JSON")
                return
            }
        } else {
            //fall back to manual serializer
            let string = JSONSerializer.serialize(object: json)
            data = [UInt8](string.utf8)
        }
        
        contentType = .JSON
        body = data
        
        send(status)
    }

    public func render(_ path: String, status: Status = .OK) {
        render(path, data: nil, status: status)
    }

    public func render(_ path: String, data: [String: Any]?, status: Status = .OK) {

        guard let renderer = self.renderSupplier?.rendererForFile(filename: path) else {
            send(error: "No renderer for this view type of \(path)")
            return
        }

        do {
            body = try renderer.renderToBytes(path: path, data: data)
            contentType = .HTML
        } catch let errorMessage {
            send(error: "An error occured: \(errorMessage)")
            return
        }

        send(status)
    }
}

func ==(left: Response, right: Response) -> Bool {
    return left.status.code == right.status.code
}
