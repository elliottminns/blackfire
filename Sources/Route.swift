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

		Route.routes.append(self)
	}
    
    class func createRoutesFromRouter(router: Router, withPath path: String) {
        addHandlers(router.gets, toRoutesWithFunction: get, withPath: path)
        addHandlers(router.posts, toRoutesWithFunction: post, withPath: path)
        addHandlers(router.puts, toRoutesWithFunction: put, withPath: path)
        addHandlers(router.deletes, toRoutesWithFunction: delete, withPath: path)
        addHandlers(router.patches, toRoutesWithFunction: patch, withPath: path)
        addHandlers(router.alls, toRoutesWithFunction: all, withPath: path)
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
		let _ = Route(method: .Get, path: path, handler: handler)
	}

	class func post(path: String, handler: Handler) {
		let _ = Route(method: .Post, path: path, handler: handler)
	}

	class func put(path: String, handler: Handler) {
		let _ = Route(method: .Put, path: path, handler: handler)
	}

	class func patch(path: String, handler: Handler) {
		let _ = Route(method: .Patch, path: path, handler: handler)
	}

	class func delete(path: String, handler: Handler) {
		let _ = Route(method: .Delete, path: path, handler: handler)
	}

	class func all(path: String, handler: Handler) {
		self.get(path, handler: handler)
		self.post(path, handler: handler)
		self.put(path, handler: handler)
		self.patch(path, handler: handler)
		self.delete(path, handler: handler)
	}

}

extension Route: Driver {

}
