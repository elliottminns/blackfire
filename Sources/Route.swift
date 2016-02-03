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

	class func any(path: String, handler: Handler) {
		self.get(path, handler: handler)
		self.post(path, handler: handler)
		self.put(path, handler: handler)
		self.patch(path, handler: handler)
		self.delete(path, handler: handler)
	}


	class func resource(path: String, controller: Controller) {
		self.get(path, handler: controller.index)
		self.post(path, handler: controller.store)

		self.get("\(path)/:id", handler: controller.show)
		self.put("\(path)/:id", handler: controller.update)
		self.delete("\(path)/:id", handler: controller.destroy)
	}

}
