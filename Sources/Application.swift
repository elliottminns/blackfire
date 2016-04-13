import Echo
import Foundation

final public class BlackfishApp {

    public static let VERSION = "0.1.3"

    private let middlewareManager: HandlerManager<MiddlewareHandler>

    private let routeManager: HandlerManager<Route>

    private var renderers: [String: Renderer]

    private let server: Server

    private let parameterManager: ParameterManager

    private let requestParser = RequestParser()

    public var port: Int {
        return runningPort
    }

    private var runningPort: Int

    public init() {
        middlewareManager = HandlerManager<MiddlewareHandler>(allowsMultiplesPerPath: true)
        routeManager = HandlerManager<Route>(allowsMultiplesPerPath: false)
        renderers = [:]
        runningPort = 3000
        server = Server()
        parameterManager = ParameterManager()
        renderers[".html"] = HTMLRenderer()
        use(middleware: StaticFileMiddleware())
        use(middleware: JSONParser())
        server.delegate = self
    }

    func dispatch(request: Request, response: Response, handlers: [Handler]?) {
        response.renderSupplier = self
        let handlers = middlewareManager.route(request: request)
        handleMiddleware(handlers: handlers, request: request, response: response)

    }

    func handleMiddleware(handlers: [Handler], request: Request, response: Response) {

        var handlers = handlers

        if let handler = handlers.popLast() {

            handler.handle(request: request, response: response) {
                self.handleMiddleware(handlers: handlers, request: request, response: response)
            }

        } else {

            let params = routeManager.paramsForPath(method: request.method.rawValue, path: request.path)

            var parameters = [String: String]()

            for (key, value) in params {
                var k = key
                if k.hasPrefix(":") {
                    k.remove(at: k.startIndex)
                }
                parameters[k] = value
            }

            let paramHandlers = parameterManager.handlersForParams(params: params)
            handleParams(handlers: paramHandlers, parameters: parameters, request: request, response: response)
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
                self.handleParams(handlers: handlers, parameters: parameters,
                                  request: request, response: response)
            }
        } else {
            let _ = parameters.popFirst()

            if parameters.count > 0 {
                handleParams(handlers: handlers, parameters: parameters,
                             request: request, response: response)
            } else {
                if let result = routeManager.routeSingle(request: request) {
                    handle(routes: [result], request: request, response: response)
                } else {
                    response.send(.NotFound)
                }
            }
        }
    }

    func handle(routes: [Handler], request: Request, response: Response) {
        
        var routes = routes

        if let route = routes.popLast() {
            route.handle(request: request, response: response) {
                self.handle(routes: routes, request: request, response: response)
            }
        }
    }

    func parseRoutes() {

        for route in Route.routes {

            self.routeManager.register(method: route.method.rawValue, handler: route)
        }
    }
}

extension BlackfishApp: ServerDelegate {
    
    public func server(_ server: Server, didRecieveConnection connection: Connection) {
        
        let data = connection.data
        
        if let request = try? requestParser.readHttpRequest(data: data) {
            
            request.parameters = [:]
            
            let response = Response(request: request, responder: self,
                                    connection: connection)
            dispatch(request: request, response: response, handlers: nil)
        }
    }
}

// MARK: - Public Methods

extension BlackfishApp {

    public func listen(port inPort: Int = 80, handler: ((error: ErrorProtocol?) -> ())? = nil) {
        
        parseRoutes()

        var port = inPort
        
        if Process.argc >= 2 {
            let secondArg = Process.arguments[1]
            if secondArg.hasPrefix("--port=") {
                let portString = secondArg.split(withCharacter: "=")[1]
                if let portInt = Int(portString) {
                    port = portInt
                }
            }
        }

        runningPort = port
        server.listen(port: port) { error in
            handler?(error: error)
        }
    }

    public func param(param: String, handler: (request: Request, 
                      response: Response, param: String, 
                      next: () -> ()) -> ()) {
        parameterManager.addHandler(handler: handler, forParam: param)
    }
}

// MARK: - Routing

extension BlackfishApp: Routing {

    public func use(path: String, router: Router) {
        Route.createRoutesFrom(router: router, withPath: path)
    }

    public func use(renderer: Renderer, ext: String) {
        renderers[ext] = renderer
    }

    public func use(path: String, controller: Controller) {
        let router = Router()
        controller.routes(router: router)
    
        Route.createRoutesFrom(router: router, withPath: path)
    }

    public func use(middleware: (request: Request,
                    response: Response, next: () -> ()) -> ()) {
        self.use(path: "/", middleware: middleware)
    }

    public func use(_ path: String,
                    middleware: (request: Request, response: Response,
                                 next: () -> ()) -> ()) {
        self.use(path: path, middleware: middleware)
    }

    public func use(path: String,
        middleware: (request: Request, response: Response,
                     next: () -> ()) -> ()) {
        let handler = MiddlewareClosureHandler(path: path,
                                               handler: middleware)
        middlewareManager.register(handler: handler)

    }

    public func use(middleware: Middleware) {
        use(path: "/", middleware: middleware)
    }

    public func use(path: String, middleware: Middleware) {
        let middlewareHandler = MiddlewareHandler(middleware: middleware,
                                                  path: path)
        middlewareManager.register(handler: middlewareHandler)
    }

    public func get(_ path: String, handler: Route.Handler) {
        Route.get(path, handler: handler)
    }

    public func put(_ path: String, handler: Route.Handler) {
        Route.put(path, handler: handler)
    }

    public func delete(_ path: String, handler: Route.Handler) {
        Route.delete(path, handler: handler)
    }

    public func post(_ path: String, handler: Route.Handler) {
        Route.post(path, handler: handler)
    }

    public func patch(_ path: String, handler: Route.Handler) {
        Route.patch(path, handler: handler)
    }

    public func all(_ path: String, handler: Route.Handler) {
        Route.all(path: path, handler: handler)
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

extension BlackfishApp: Responder {
    
    public func send(response: Response) {

        let connection = response.connection

        var responseString = ""
        responseString = "HTTP/1.1 \(response.status.code) \(response.status.description)\r\n"
        
        var headers = response.headers()
        
        if response.body.count >= 0 {
            headers["Content-Length"] = "\(response.body.count)"
        }
        
        if true && response.body.count != -1 {
            headers["Connection"] = "keep-alive"
        }
        
        for (name, value) in headers {
            responseString += "\(name): \(value)\r\n"
        }
        
        responseString += "\r\n"
        var data: Data = Data(string: responseString)
        data.append(response.body)
        
        connection.write(data: data)
        
        response.request?.fireOnFinish()
        response.request?.session.destroy()
    }
}
