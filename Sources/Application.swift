
import Foundation

final public class BlackfishApp {

    public static let VERSION = "0.1.3"

    private let middlewareManager: HandlerManager<MiddlewareHandler>

    private let routeManager: HandlerManager<Route>

    private var renderers: [String: Renderer]
    
    private let server: SocketServer
    
    private let parameterManager: ParameterManager

    public var port: Int {
        return runningPort
    }

    private var runningPort: Int

    public init() {
        middlewareManager = HandlerManager<MiddlewareHandler>(allowsMultiplesPerPath: true)
        routeManager = HandlerManager<Route>(allowsMultiplesPerPath: false)
        renderers = [:]
        runningPort = 3000
        server = SocketServer()
        parameterManager = ParameterManager()
        renderers[".html"] = HTMLRenderer()
        use(middleware: StaticFileMiddleware())
        use(middleware: JSONParser())
        server.delegate = self
    }
    
    func dispatch(request request: Request, response: Response, handlers: [Handler]?) {
        response.renderSupplier = self
        let handlers = middlewareManager.route(request)
        handleMiddleware(handlers, request: request, response: response)

    }
    
    func handleMiddleware(handlers: [Handler], request: Request, response: Response) {
        
        var handlers = handlers
        
        if let handler = handlers.popLast() {
            
            handler.handle(request: request, response: response) {
                self.handleMiddleware(handlers, request: request, response: response)
            }
            
        } else {
            
            let params = routeManager.paramsForPath(request.method.rawValue, path: request.path)
            
            var parameters = [String: String]()
            
            for (key, value) in params {
                var k = key
                if k.hasPrefix(":") {
                    k.removeAtIndex(k.startIndex)
                }
                parameters[k] = value
            }
            
            let paramHandlers = parameterManager.handlersForParams(params)
            handleParams(paramHandlers, parameters: parameters, request: request, response: response)
        }
    }
    
    func handleParams(handlers: [String: [ParameterManager.Handler]],
                      parameters: [String: String], request: Request, response: Response) {
        
        var handlers = handlers
        var parameters = parameters
        
        if let param = parameters.first, let keyHandlers = handlers[param.0] where keyHandlers.count > 0 {
            
            let key = param.0
            let value = param.1
            
            var kHandlers = keyHandlers
            
            let handler = kHandlers.removeFirst()
            
            handlers[key] = kHandlers;
            
            handler(request: request, response: response, param: value) {
                self.handleParams(handlers, parameters: parameters,
                                  request: request, response: response)
            }
        } else {
            parameters.popFirst()
            
            if parameters.count > 0 {
                handleParams(handlers, parameters: parameters,
                             request: request, response: response)
            } else {
                if let result = routeManager.routeSingle(request) {
                    handleRoutes([result], request: request, response: response)
                } else {
                    response.status = .NotFound
                    response.send(text: "Page not found")
                }
            }
        }
    }
    
    func handleRoutes(routes: [Handler], request: Request, response: Response) {
        var routes = routes
        if let route = routes.popLast() {
            route.handle(request: request, response: response) {
                self.handleRoutes(routes, request: request, response: response)
            }
        }
    }

    func parseRoutes() {

        for route in Route.routes {
            
            self.routeManager.register(route.method.rawValue, handler: route)
        }
    }
}

extension BlackfishApp: SocketServerDelegate {
    func socketServer(socketServer: SocketServer,
                      didRecieveRequest request: Request,
                                        withResponse response: Response) {
        self.dispatch(request: request, response: response, handlers: nil)
    }
}

// MARK: - Public Methods

extension BlackfishApp {

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
            try server.start(port)
            runningPort = port
            handler?(error: nil)
            server.loop()
        } catch {
            handler?(error: error)
        }
    }
    
    public func param(param: String, handler: (request: Request, response: Response, param: String, next: () -> ()) -> ()) {
        parameterManager.addHandler(handler, forParam: param)
    }
}

// MARK: - Routing

extension BlackfishApp: Routing {

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

extension BlackfishApp: RendererSupplier {
    public func rendererForFile(filename: String) -> Renderer? {

        for (key, value) in renderers {
            if filename.hasSuffix(key) {
                return value
            }
        }

        return nil
    }
}
