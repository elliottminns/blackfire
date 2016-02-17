import Blackfish

class Test: Controller {
    
    func routes(router: Router) {
        router.get("/", handler: index)
        router.post("/update", handler: formUpdate)
    }
    
    var index: Route.Handler {
        return { request, response in
            response.send(text: "Hello Index")
        }
    }
    
    func formUpdate(request: Request, response: Response) {
        response.send(text: "Form updated")
    }
}

let app = Blackfish()

app.use(path: "/test", controller: Test())

app.get("/") { request, response in
    response.send(text: "Hello World")
}

app.listen(port: 3000) { error in
    if error == nil {
        print("App listening on port 3000")
    } else {
        print("Error")
    }
}
