import Blackfish

class Index: Controller {
    
    func routes(router: Router) {
        router.get("/", handler: index)
        router.post("/", handler: formUpdate)
    }
    
    var index: Route.Handler {
        return { request, response in
            response.render("welcome.html")
        }
    }
    
    func formUpdate(request: Request, response: Response) {
        
        print("Files: \(request.files.count)")
        response.redirect("/")
    }
}

class Logger: Middleware {
    func handle(request: Request, response: Response, next: (() -> ())) {
        print(request.path)
        next()
    }
}

let app = Blackfish()

app.use(path: "/", controller: Index())
app.use(path: "/", middleware: Logger())
app.use(middleware: Multiparser())

app.listen(port: 3000) { error in
    if error == nil {
        print("App listening on port 3000")
    } else {
        print("Error")
    }
}
