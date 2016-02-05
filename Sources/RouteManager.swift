//
// Based on HttpRouter from Swifter (https://github.com/glock45/swifter) by Damian Kołakowski.
//

import Foundation

class RouteManager {
    
    typealias DriverType = Route
    
    let pathTree: PathTree<Route.Handler>
    
    init() {
        pathTree = PathTree<Route.Handler>()
    }
}

extension RouteManager: RouteDriver {
    
}
