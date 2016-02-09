import Foundation

public protocol Responder: class {
    func sendResponse(response: Response)
}

/**
    Responses are objects responsible for returning
    data to the HTTP request such as the body, status
    code and headers.
 */
public class Response {

    public enum SerializationError: ErrorType {
        case InvalidObject
        case NotSupported
    }

    public var contentType: ContentType
    public var status: Status
    public var body: [UInt8]
    public var cookies: [String: String] = [:]
    
    unowned let request: Request
    unowned let responder: Responder
    let socket: Socket

    public enum ContentType {
        case Text, HTML, JSON, None
    }

    public enum Status {
        case OK, Created, Accepted
        case MovedPermanently
        case BadRequest, Unauthorized, Forbidden, NotFound
        case Error
        case Unknown
        case Custom(Int)

        public var code: Int {
            switch self {
                case .OK: return 200
                case .Created: return 201
                case .Accepted: return 202

                case .MovedPermanently: return 301

                case .BadRequest: return 400
                case .Unauthorized: return 401
                case .Forbidden: return 403
                case .NotFound: return 404

                case .Error: return 500

                case .Unknown: return 0
                case .Custom(let code):
                    return code
            }
        }
    }

    var reasonPhrase: String {
        switch self.status {
        case .OK:
            return "OK"
        case .Created:
            return "Created"
        case .Accepted:
            return "Accepted"

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
        case .Custom:
            return "Custom"
        }
    }

    func headers() -> [String: String] {
        var headers = ["Server" : "Blackfish \(Blackfish.VERSION)"]

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
        default:
            break
        }

        return headers
    }

    init(request: Request, responder: Responder, socket: Socket) {
        self.request = request
        self.status = .OK
        self.contentType = .Text
        self.body = []
        self.responder = responder
        self.socket = socket
    }
}

// MARK: - Public Methods

extension Response {

    public func send() {
        
        responder.sendResponse(self)
    }

    public func send(text text: String) {
        
        body = [UInt8](text.utf8)
        contentType = .Text
        status = .OK
        send()
    }

    public func send(error error: String) {
        
        let text = "{\n\t\"error\": true,\n\t\"message\":\"\(error)\"\n}"
        body = [UInt8](text.utf8)
        contentType = .JSON
        status = .Error
        send()
    }

    public func send(html html: String) {
        
        let serialised = "<html><meta charset=\"UTF-8\"><body>\(html)</body></html>"
        body = [UInt8](serialised.utf8)
        contentType = .HTML
        status = .OK
        send()
    }
    
    public func send(json json: AnyObject) {
        
        let data: [UInt8]
        
        if NSJSONSerialization.isValidJSONObject(json) {
            
            do {
                let json = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
                data = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(json.bytes), count: json.length))
            } catch {
                self.send(error: "Server error")
                return
            }
        } else {
            //fall back to manual serializer
            let string = JSONSerializer.serialize(json)
            data = [UInt8](string.utf8)
        }
        
        
        contentType = .JSON
        status = .OK
        body = data
        
        self.send()
    }
    
    public func render(path: String) {
        
        let htmlView = HTMLRenderer()
        
        do {
            body = try htmlView.render("Resources/" + path)
            contentType = .HTML
            status = .OK
        } catch {
            status = .Error
            contentType = .Text
            body = [UInt8]("An error occured".utf8)
        }
        
        send()
    }
}

func ==(left: Response, right: Response) -> Bool {
    return left.status.code == right.status.code
}
