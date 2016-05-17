import Foundation
import Echo

public enum Event {
    case OnFinish
}

public class Request {

    public let method: HTTPMethod

    public var params: [String: String] {
        get {
            return parameters
        }

        set {
            parameters = newValue;
        }
    }
    
    var listeners: [Event: [() -> ()]]

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

    init(request: HTTPRequest) {
        self.path = request.path
        self.headers = request.headers
        self.method = request.method
        self.listeners = [:]
    }
    
    public func addListener(event: Event, listener: () -> Void) {
        if listeners[event] == nil {
            listeners[event] = []
        }
        
        listeners[event]?.append(listener)
    }

    public func getHeader(header: String) -> String? {
        return headers[header]
    }

    public func setValue(value: String, forHeader header: String) {
        headers[header] = value
    }
    
    func fireOnFinish() {
        fire(event: Event.OnFinish)
    }
    
    func fire(event: Event) {
        if let listeners = self.listeners[event] {
            for listener in listeners {
                listener()
            }
        }
    }
}
