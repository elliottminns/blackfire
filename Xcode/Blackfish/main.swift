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

let app = BlackfishApp()

app.use(path: "/", controller: Index())
//app.use(middleware: Multiparser())
app.use(middleware: Logger())

app.get("/user/:id") { request, response in
    response.send(text: request.parameters["id"]!)
}

app.param("id") { (request, response, param, next) in
//    print(param)
    next()
}

app.listen(port: 3000) { error in
    if error == nil {
        print("App listening on port 3000")
    } else {
        print("Error")
    }
}
