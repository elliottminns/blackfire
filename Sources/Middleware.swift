
final public class Middleware {
    
    public typealias Handler = ((request: Request, response: Response, next: (() -> ())) -> Void)
    
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