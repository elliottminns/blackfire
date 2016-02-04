
protocol Routing {
    func use(middleware middleware: Middleware)
    func get(path: String, handler: Route.Handler)
    func put(path: String, handler: Route.Handler)
    func delete(path: String, handler: Route.Handler)
    func post(path: String, handler: Route.Handler)
    func patch(path: String, handler: Route.Handler)
    func all(path: String, handler: Route.Handler)
}

public class Router: Routing {
    
    var middleware: [Middleware] = []
    var gets: [String: Route.Handler] = [:]
    var puts: [String: Route.Handler] = [:]
    var deletes: [String: Route.Handler] = [:]
    var posts: [String: Route.Handler] = [:]
    var patches: [String: Route.Handler] = [:]
    var alls: [String: Route.Handler] = [:]
    
    public func use(middleware middleware: Middleware) {
        self.middleware.append(middleware)
    }
    
    public func get(path: String, handler: Route.Handler) {
        gets[path] = handler
    }
    
    public func put(path: String, handler: Route.Handler) {
        puts[path] = handler
    }
    
    public func delete(path: String, handler: Route.Handler) {
        deletes[path] = handler;
    }
    
    public func post(path: String, handler: Route.Handler) {
        posts[path] = handler;
    }
    
    public func patch(path: String, handler: Route.Handler) {
        patches[path] = handler;
    }
    
    public func all(path: String, handler: Route.Handler) {
        alls[path] = handler;
    }
}