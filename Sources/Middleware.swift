

public protocol Middleware {
    func handle(request: Request, response: Response, next: (() -> ())) -> Void
}

class MiddlewareHandler {
    
    let middleware: Middleware
    let path: String
    
    init(middleware: Middleware, path: String) {
        self.path = path
        self.middleware = middleware
    }
    
}

extension MiddlewareHandler: Handler {
    
    func handle(request request: Request, response: Response, next: (() -> ())) {
        middleware.handle(request, response: response, next: next)
    }
}