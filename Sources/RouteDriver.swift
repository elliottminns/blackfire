
import Foundation

protocol Driver {
    
    associatedtype Handler
    
    var path: String { get }
    var handler: Handler { get }
}

protocol RouteDriver {
    
    associatedtype DriverType: Driver
    
    var pathTree: PathTree<DriverType.Handler> { get }
    
    func hasMultiples() -> Bool
}

extension RouteDriver {
    
    func register(driver: DriverType) {
        let path = "*/" + driver.path
        pathTree.addHandler(driver.handler, toPath: path, overwrite: !hasMultiples())
    }
    
    func register(method: String?, driver: DriverType, handler: DriverType.Handler) {
        let path: String
        
        if let method = method {
            path = method + "/" + driver.path
        } else {
            path = "*/" + driver.path
        }
        
        pathTree.addHandler(handler, toPath: path, overwrite: hasMultiples())
    }
    
    func routeSingle(request: Request) -> DriverType.Handler? {
        let path: String
        
        if request.method != Request.Method.Unknown {
            path = request.method.rawValue + "/" + request.path
        } else {
            path = "*/" + request.path
        }
        
        return pathTree.findValue(path)
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

