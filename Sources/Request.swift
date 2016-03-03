import Foundation
import Vaquita

public enum Event {
    case OnFinish
}

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

    init(method: Method) {
        self.method = method
        listeners = [:]
    }
    
    public func addListener(event event: Event, listener: () -> Void) {
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
        fireEvent(Event.OnFinish)
    }
    
    func fireEvent(event: Event) {
        if let listeners = self.listeners[event] {
            for listener in listeners {
                listener()
            }
        }
    }
}
