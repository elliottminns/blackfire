

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
    
    func handle(request: Request, response: Response, next: (() -> ())) {
        middleware.handle(request: request, response: response, next: next)
    }
}

class MiddlewareClosureHandler {

    let path: String
    let handler: (request: Request, response: Response, next: () -> ()) -> ()
    
    init(path: String, handler: (request: Request, 
        response: Response, next: () -> ()) -> ()) {
        self.path = path
        self.handler = handler
    }

}

extension MiddlewareClosureHandler: Handler {

    func handle(request: Request, response: Response, next: () -> ()) {
        self.handler(request: request, response: response, next: next)
    }
}
