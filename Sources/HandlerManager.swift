
import Foundation

protocol Handler {
    
    func handle(request: Request, response: Response, next: (() -> ()))
    
    var path: String { get }
    
}

final class HandlerManager<T: Handler> {
    
    let allowsMultiples: Bool
    
    let pathTree: PathTree<Handler>
    
    init(allowsMultiplesPerPath: Bool) {
        allowsMultiples = allowsMultiplesPerPath
        pathTree = PathTree<Handler>()
    }
    
}

extension HandlerManager {
    
    func paramsForPath(method: String?, path: String) -> [String: String] {
        let fullPath: String
        if let method = method {
            fullPath = method + "/" + path
        } else {
            fullPath = "*/" + path
        }
        return pathTree.paramsForPath(path: fullPath)
    }
    
    func register(handler: Handler) {
        let path = "*/" + handler.path
        pathTree.addHandler(handler: handler, toPath: path, overwrite: !allowsMultiples)
    }
    
    func register(method: String?, handler: Handler) {
        let path: String
        
        if let method = method {
            path = method + "/" + handler.path
        } else {
            path = "*/" + handler.path
        }
        
        pathTree.addHandler(handler: handler, toPath: path, overwrite: allowsMultiples)
    }
    
    func routeSingle(request: Request) -> Handler? {
        
        let path: String
        
        if request.method != Request.Method.Unknown {
            path = request.method.rawValue + "/" + request.path
        } else {
            path = "*/" + request.path
        }
        
        let result = pathTree.findValue(path: path)
        
        for (key, value) in result.params {
            request.params[key] = value
        }
        
        return result.handler
    }

    func route(request: Request) -> [Handler] {
        
        let path: String

        if request.method != Request.Method.Unknown {
            path = request.method.rawValue + "/" + request.path
        } else {
            path = "*/" + request.path
        }
        
        let result = pathTree.findValues(path: path)
        
        for (key, value) in result.params {
            request.params[key] = value
        }
        
        return result.handlers
    }
}

