
public protocol MiddlewareHandler {
    func handle(request: Request, response: Response, next: (() -> ()))
}

final public class Middleware {
    
    public typealias Handler = (request: Request, response: Response, next: (() -> ())) -> Void
    
    let path: String
    let handler: Handler
    
    public init(path: String, handler: Middleware.Handler) {
        self.path = path
        self.handler = handler
    }
    
    public init(handler: Handler) {
        self.path = "/"
        self.handler = handler
    }
}

extension Middleware: Driver {
    
}

extension Middleware: MiddlewareHandler {
    
    public func handle(request: Request, response: Response, next: (() -> ())) {
        self.handler(request: request, response: response, next: next)
    }
    
}