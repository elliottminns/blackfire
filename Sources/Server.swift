
import Foundation

public class Blackfish: SocketServer {

    public static let VERSION = "0.1.3"

    private let middlewareManager: MiddlewareManager
    
    private let routeManager: RouteManager
    
    private var renderers: [String: Renderer]

    public override init() {
        middlewareManager = MiddlewareManager()
        routeManager = RouteManager()
        renderers = [:]
        super.init()
        
        renderers[".html"] = HTMLRenderer()
    }
    
    override func dispatch(request request: Request, response: Response, handlers: [Middleware.Handler]?) {
        
        //check in file system
        let filePath = "Public" + request.path
        
        let fileManager = NSFileManager.defaultManager()
        var isDir: ObjCBool = false
        
        if fileManager.fileExistsAtPath(filePath, isDirectory: &isDir) {
            // File exists
            if let fileBody = NSData(contentsOfFile: filePath) {
                var array = [UInt8](count: fileBody.length, repeatedValue: 0)
                fileBody.getBytes(&array, length: fileBody.length)
                
                response.status = .OK
                response.body = array
                response.contentType = .Text
                response.send()
                return
            }
        }
        
        if let handlers = handlers {
            
            var handlers = handlers
            
            if let handler = handlers.popLast() {
                
                handler(request: request, response: response, next: { () -> () in
                    self.dispatch(request: request, response: response, handlers: handlers)
                })
                
            } else {
                if let result = routeManager.routeSingle(request) {
                    result(request: request, response: response)
                } else {
                    super.dispatch(request: request, response: response, handlers: nil)
                }
            }
            
        } else {
            let handlers = middlewareManager.route(request)
            dispatch(request: request, response: response, handlers: handlers)
        }
    }
    
    func parseRoutes() {
        
        for route in Route.routes {
            
            self.routeManager.register(route.method.rawValue, driver: route) { request, response in
                
                // Grab request params
                let routePaths = route.path.split("?")[0].split("/")
                
                for (index, path) in routePaths.enumerate() {
                    if path.hasPrefix(":") {
                        let requestPaths = request.path.split("/")
                        if requestPaths.count > index {
                            var trimPath = path
                            trimPath.removeAtIndex(path.startIndex)
                            request.parameters[trimPath] = requestPaths[index]
                        }
                    }
                }
                
                Session.start(request)
                
                route.handler(request: request, response: response)
            }
        }
    }
}

// MARK: - Public Methods

extension Blackfish {
    
    public func listen(port inPort: Int = 80, handler: ((error: ErrorType?) -> ())? = nil) {
        
        parseRoutes()
        
        var port = inPort
        
        if Process.arguments.count >= 2 {
            let secondArg = Process.arguments[1]
            if secondArg.hasPrefix("--port=") {
                let portString = secondArg.split("=")[1]
                if let portInt = Int(portString) {
                    port = portInt
                }
            }
        }
        
        do {
            try self.start(port)
            handler?(error: nil)
            self.loop()
        } catch {
            handler?(error: error)
        }
    }
    
    public func use(path path: String, router: Router) {
        Route.createRoutesFromRouter(router, withPath: path)
    }
    
    public func use(renderer renderer: Renderer, ext: String) {
        renderers[ext] = renderer
    }
}

// MARK: - Routing

extension Blackfish: Routing {
    
    public func use(middleware middleware: Middleware) {
        middlewareManager.register(middleware)
    }
    
    public func get(path: String, handler: Route.Handler) {
        Route.get(path, handler: handler)
    }
    
    public func put(path: String, handler: Route.Handler) {
        Route.put(path, handler: handler)
    }
    
    public func delete(path: String, handler: Route.Handler) {
        Route.delete(path, handler: handler)
    }
    
    public func post(path: String, handler: Route.Handler) {
        Route.post(path, handler: handler)
    }
    
    public func patch(path: String, handler: Route.Handler) {
        Route.patch(path, handler: handler)
    }
    
    public func all(path: String, handler: Route.Handler) {
        Route.all(path, handler: handler)
    }
    
}

// MARK: - RendererSupplier

extension Blackfish: RendererSupplier {
    public func rendererForFile(filename: String) -> Renderer? {
        
        for (key, value) in renderers {
            if filename.hasSuffix(key) {
                return value
            }
        }
        
        return nil
    }
}
