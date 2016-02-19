
import Foundation

public class Blackfish: SocketServer {

    public static let VERSION = "0.1.3"

    private let middlewareManager: HandlerManager<MiddlewareHandler>

    private let routeManager: HandlerManager<Route>

    private var renderers: [String: Renderer]

    public var port: Int {
        return runningPort
    }

    private var runningPort: Int

    public override init() {
        middlewareManager = HandlerManager<MiddlewareHandler>(allowsMultiplesPerPath: false)
        routeManager = HandlerManager<Route>(allowsMultiplesPerPath: true)
        renderers = [:]
        runningPort = 3000
        super.init()

        renderers[".html"] = HTMLRenderer()
    }

    override func dispatch(request request: Request, response: Response, handlers: [Handler]?) {

        response.renderSupplier = self

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

                handler.handle(request: request, response: response, next: { () -> () in
                    self.dispatch(request: request, response: response, handlers: handlers)
                })

            } else {
                
                if let result = routeManager.routeSingle(request) {
                    result.handle(request: request, response: response, next: { 
                        
                    })
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
            
            self.routeManager.register(route.method.rawValue, handler: route)
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
            runningPort = port
            handler?(error: nil)
            self.loop()
        } catch {
            handler?(error: error)
        }
    }
}

// MARK: - Routing

extension Blackfish: Routing {

    public func use(path path: String, router: Router) {
        Route.createRoutesFromRouter(router, withPath: path)
    }
    
    public func use(renderer renderer: Renderer, ext: String) {
        renderers[ext] = renderer
    }
    
    public func use(path path: String, controller: Controller) {
        let router = Router()
        controller.routes(router)
        Route.createRoutesFromRouter(router, withPath: path)
    }

    public func use(middleware middleware: (request: Request, 
                    response: Response, next: () -> ()) -> ()) {
        self.use(path: "/", middleware: middleware)
    }

    public func use(path: String,
                    middleware: (request: Request, response: Response, 
                                 next: () -> ()) -> ()) {
        self.use(path: path, middleware: middleware)
    }

    public func use(path path: String, 
        middleware: (request: Request, response: Response, 
                     next: () -> ()) -> ()) {
        let handler = MiddlewareClosureHandler(path: path, 
                                               handler: middleware)
        middlewareManager.register(handler)

    }
    
    public func use(middleware middleware: Middleware) {
        use(path: "/", middleware: middleware)
    }
    
    public func use(path path: String, middleware: Middleware) {
        let middlewareHandler = MiddlewareHandler(middleware: middleware,
                                                  path: path)
        middlewareManager.register(middlewareHandler)
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
