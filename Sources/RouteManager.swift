
class RouteManager {

    typealias DriverType = Route

    let pathTree: PathTree<Route.Handler>

    init() {
        pathTree = PathTree<Route.Handler>()
    }

}

extension RouteManager: RouteDriver {

    func hasMultiples() -> Bool {
        return false
    }

}
