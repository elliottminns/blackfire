
protocol Routing {
    func use(middleware: Middleware)
    func get(_ path: String, handler: Route.Handler)
    func put(_ path: String, handler: Route.Handler)
    func delete(_ path: String, handler: Route.Handler)
    func post(_ path: String, handler: Route.Handler)
    func patch(_ path: String, handler: Route.Handler)
    func all(_ path: String, handler: Route.Handler)
}

public class Router: Routing {
    
    var middleware: [Middleware] = []
    var gets: [String: Route.Handler] = [:]
    var puts: [String: Route.Handler] = [:]
    var deletes: [String: Route.Handler] = [:]
    var posts: [String: Route.Handler] = [:]
    var patches: [String: Route.Handler] = [:]
    var alls: [String: Route.Handler] = [:]
    
    public init() {
        self.setupRoutes()
    }
    
    public func setupRoutes() {
        
    }
    
    final public func use(middleware: Middleware) {
        self.middleware.append(middleware)
    }
    
    final public func get(_ path: String, handler: Route.Handler) {
        gets[path] = handler
    }
    
    final public func put(_ path: String, handler: Route.Handler) {
        puts[path] = handler
    }
    
    final public func delete(_ path: String, handler: Route.Handler) {
        deletes[path] = handler;
    }
    
    final public func post(_ path: String, handler: Route.Handler) {
        posts[path] = handler;
    }
    
    final public func patch(_ path: String, handler: Route.Handler) {
        patches[path] = handler;
    }
    
    public func all(_ path: String, handler: Route.Handler) {
        alls[path] = handler;
    }
}