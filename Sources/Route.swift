import Echo

public class Route {

	static var routes: [Route] = []

    public typealias Handler = ((request: Request, response: Response) -> Void)
    public typealias NextHandler = ((request: Request, response: Response, 
                                    next: () -> Void) -> Void)

	let method: HTTPMethod
	let path: String
	let handler: Handler?
    let nextHandler: NextHandler?

	init(method: HTTPMethod, path: String, handler: Handler) {
		self.method = method
		self.path = path
		self.handler = handler
        self.nextHandler = nil
	}
    
    init(method: HTTPMethod, path: String, nextHandler: NextHandler) {
        self.method = method
        self.path = path
        self.nextHandler = nextHandler
        self.handler = nil
    }
    
    class func createRoutesFrom(router: Router, withPath path: String) {
        add(handlers: router.gets, toRoutesWithFunction: get, withPath: path)
        add(handlers: router.posts, toRoutesWithFunction: post, withPath: path)
        add(handlers: router.puts, toRoutesWithFunction: put, withPath: path)
        add(handlers: router.deletes, toRoutesWithFunction: delete, withPath: path)
        add(handlers: router.patches, toRoutesWithFunction: patch, withPath: path)
        add(handlers: router.alls, toRoutesWithFunction: all, withPath: path)
    }
    
    class func add(method: HTTPMethod, path: String,
                   handler: Handler) {
        let route = Route(method: method, path: path, handler: handler)
        self.routes.append(route)
    }

    class func add(method: HTTPMethod, path: String,
                   handler: NextHandler) {
        let route = Route(method: method, path: path, nextHandler: handler)
        self.routes.append(route)
    }

    class func add(handlers: [String: Handler],
        toRoutesWithFunction function: ((path: String, handler: Handler) -> Void),
        withPath path: String) {
            for (postPath, handler) in handlers {
                let fullPath = "\(path)\(postPath)"
                function(path: fullPath, handler: handler)
            }
    }
    
    class func get(_ path: String, handler: NextHandler) {
        self.add(method: .GET, path: path, handler: handler)
    }

	class func get(_ path: String, handler: Handler) {
        self.add(method: .GET, path: path, handler: handler)
	}

	class func post(_ path: String, handler: Handler) {
        self.add(method: .POST, path: path, handler: handler)
	}

	class func put(_ path: String, handler: Handler) {
        self.add(method: .PUT, path: path, handler: handler)
	}

	class func patch(_ path: String, handler: Handler) {
		self.add(method: .PATCH, path: path, handler: handler)
	}

	class func delete(_ path: String, handler: Handler) {
		self.add(method: .DELETE, path: path, handler: handler)
	}

	class func all(path: String, handler: Handler) {
		self.get(path, handler: handler)
		self.post(path, handler: handler)
		self.put(path, handler: handler)
		self.patch(path, handler: handler)
		self.delete(path, handler: handler)
	}

}

extension Route: Handler {
    
    func handle(request: Request, response: Response, next: (() -> ())) {
            
        // Grab request params
        let routePaths = self.path.split(withCharacter: "?")[0].split(withCharacter: "/")
        
        for (index, path) in routePaths.enumerated() {
            if path.hasPrefix(":") {
                let requestPaths = request.path.split(withCharacter: "/")
                if requestPaths.count > index {
                    var trimPath = path
                    trimPath.remove(at: path.startIndex)
                    request.parameters[trimPath] = requestPaths[index]
                }
            }
        }
        
        Session.start(request)
        
        if let handler = handler {
            handler(request: request, response: response)
            next()
        } else if let handler = nextHandler {
            handler(request: request, response: response, next: next)
        }
    }
}
