
import Foundation

protocol Driver {
    
    typealias Handler
    
    var path: String { get }
    var handler: Handler { get }
}

protocol RouteDriver {
    
    typealias DriverType: Driver
    
    var pathTree: PathTree<DriverType.Handler> { get }
}

extension RouteDriver {
    
    func register(driver: DriverType) {
        let path = "*/" + driver.path
        pathTree.addHandler(driver.handler, toPath: path)
    }
    
    func register(method: String?, driver: DriverType, handler: DriverType.Handler) {
        let path: String
        
        if let method = method {
            path = method + "/" + driver.path
        } else {
            path = "*/" + driver.path
        }
        
        pathTree.addHandler(handler, toPath: path)
    }
    
    func routeSingle(request: Request) -> DriverType.Handler? {
        return self.route(request).last
    }

    func route(request: Request) -> [DriverType.Handler] {
        let path: String

        if request.method != Request.Method.Unknown {
            path = request.method.rawValue + "/" + request.path
        } else {
            path = "*/" + request.path
        }
        
        return pathTree.findValues(path)
    }
}

