public class Route {

	static var routes: [Route] = []

    public typealias Handler = ((request: Request, response: Response) -> Void)

	let method: Request.Method
	let path: String
	let handler: Handler

	init(method: Request.Method, path: String, handler: Handler) {
		self.method = method
		self.path = path
		self.handler = handler
	}
    
    class func createRoutesFromRouter(router: Router, withPath path: String) {
        addHandlers(router.gets, toRoutesWithFunction: get, withPath: path)
        addHandlers(router.posts, toRoutesWithFunction: post, withPath: path)
        addHandlers(router.puts, toRoutesWithFunction: put, withPath: path)
        addHandlers(router.deletes, toRoutesWithFunction: delete, withPath: path)
        addHandlers(router.patches, toRoutesWithFunction: patch, withPath: path)
        addHandlers(router.alls, toRoutesWithFunction: all, withPath: path)
    }
    
    class func add(method method: Request.Method, path: String, handler: Handler) {
        let route = Route(method: method, path: path, handler: handler)
        self.routes.append(route)
    }

    class func addHandlers(handlers: [String: Handler],
        toRoutesWithFunction function: ((path: String, handler: Handler) -> Void),
        withPath path: String) {
            for (postPath, handler) in handlers {
                let fullPath = "\(path)\(postPath)"
                function(path: fullPath, handler: handler)
            }
    }

	class func get(path: String, handler: Handler) {
        self.add(method: .Get, path: path, handler: handler)
	}

	class func post(path: String, handler: Handler) {
        self.add(method: .Post, path: path, handler: handler)
	}

	class func put(path: String, handler: Handler) {
        self.add(method: .Put, path: path, handler: handler)
	}

	class func patch(path: String, handler: Handler) {
		self.add(method: .Patch, path: path, handler: handler)
	}

	class func delete(path: String, handler: Handler) {
		self.add(method: .Delete, path: path, handler: handler)
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
    func handle(request request: Request, response: Response, next: (() -> ())) {
            
        // Grab request params
        let routePaths = self.path.splitWithCharacter("?")[0].splitWithCharacter("/")
        
        for (index, path) in routePaths.enumerated() {
            if path.hasPrefix(":") {
                let requestPaths = request.path.splitWithCharacter("/")
                if requestPaths.count > index {
                    var trimPath = path
                    trimPath.remove(at: path.startIndex)
                    request.parameters[trimPath] = requestPaths[index]
                }
            }
        }
        
        Session.start(request)
        
        self.handler(request: request, response: response)
        
    }
}
