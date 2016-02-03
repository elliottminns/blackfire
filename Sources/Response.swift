import Foundation

public protocol ResponseWriter {
    func write(data: [UInt8])
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

    typealias WriteClosure = (ResponseWriter) throws -> Void
    typealias Writer = Socket throws -> Void

    public var status: Status
    public var body: [UInt8]
    var contentType: ContentType
    public var cookies: [String: String] = [:]
    unowned let request: Request
    unowned let socket: Socket

    enum ContentType {
        case Text, Html, Json, None
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

    func content() -> (length: Int, writeClosure: WriteClosure?) {
        return (self.body.count, { writer in
            writer.write(self.body)
        })
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
        case .Json:
            headers["Content-Type"] = "application/json"
        case .Html:
            headers["Content-Type"] = "text/html"
        default:
            break
        }

        return headers
    }

    init(request: Request, socket: Socket) {
        self.request = request
        self.status = .OK
        self.contentType = .Text
        self.body = []
        self.socket = socket
    }
}

// MARK: - Public Methods

extension Response {

    public func send() {
        
        defer {
//            Session.close(request: request, response: self)
            socket.release()
        }
        
        do {
            try socket.writeUTF8("HTTP/1.1 \(status.code) \(reasonPhrase)\r\n")
            
            var headers = self.headers()
            
            if body.count >= 0 {
                headers["Content-Length"] = "\(body.count)"
            }
            
            if true && body.count != -1 {
                headers["Connection"] = "keep-alive"
            }
            
            for (name, value) in headers {
                try socket.writeUTF8("\(name): \(value)\r\n")
            }
            
            try socket.writeUTF8("\r\n")
            
            try socket.writeUInt8(body)
            
        } catch {
            print(error)
        }
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
        contentType = .Json
        status = .Error
        send()
    }

    public func send(html html: String) {
        
        let serialised = "<html><meta charset=\"UTF-8\"><body>\(html)</body></html>"
        body = [UInt8](serialised.utf8)
        contentType = .Html
        status = .OK
        send()
    }
    
    public func render(path: String) {
        
        let htmlView = HTMLRenderer()
        
        do {
            body = try htmlView.render("Resources/" + path)
            contentType = .Html
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
