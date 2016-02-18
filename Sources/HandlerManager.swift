
import Foundation

protocol Handler {
    
    func handle(request request: Request, response: Response, next: (() -> ()))
    
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
    
    func register(handler: Handler) {
        let path = "*/" + handler.path
        pathTree.addHandler(handler, toPath: path, overwrite: !allowsMultiples)
    }
    
    func register(method: String?, handler: Handler) {
        let path: String
        
        if let method = method {
            path = method + "/" + handler.path
        } else {
            path = "*/" + handler.path
        }
        
        pathTree.addHandler(handler, toPath: path, overwrite: allowsMultiples)
    }
    
    func routeSingle(request: Request) -> Handler? {
        let path: String
        
        if request.method != Request.Method.Unknown {
            path = request.method.rawValue + "/" + request.path
        } else {
            path = "*/" + request.path
        }
        
        return pathTree.findValue(path)
    }

    func route(request: Request) -> [Handler] {
        let path: String

        if request.method != Request.Method.Unknown {
            path = request.method.rawValue + "/" + request.path
        } else {
            path = "*/" + request.path
        }
        
        return pathTree.findValues(path)
    }
}

