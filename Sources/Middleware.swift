
public protocol MiddlewareHandler {
    func handle(request: Request, response: Response, next: (() -> ())) -> Void
}

public class Middleware {
    
    public typealias Handler = (request: Request, response: Response, next: (() -> ())) -> Void
    
    let path: String
    
    var handler: Handler {
        
        if let handler = handlerStore {
            return handler
        } else {
            return handle
        }
    }
    
    var handlerStore: Handler?
    
    public init(path: String, handler: Middleware.Handler) {
        self.path = path
        self.handlerStore = handler
    }
    
    public init(handler: Handler) {
        self.path = "/"
        self.handlerStore = handler
    }
    
    public init(path: String) {
        self.path = "/"
        self.handlerStore = self.handle
    }
    
    public init() {
        self.path = "/"
        self.handlerStore = self.handle
    }
}

extension Middleware: Driver {
    
}

extension Middleware: MiddlewareHandler {
    
    public func handle(request: Request, response: Response, next: (() -> ())) {

    }
}