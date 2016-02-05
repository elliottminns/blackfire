
class MiddlewareManager {
    typealias DriverType = Middleware
    
    let pathTree: PathTree<Middleware.Handler>
    
    init() {
        pathTree = PathTree<Middleware.Handler>()
    }
}

extension MiddlewareManager: RouteDriver {
    
}