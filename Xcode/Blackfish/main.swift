import Blackfish
import Echo


class FibTask: Worker {
    func task() {
        for i in 0 ..< 10 {
            fib(i)
        }
    }
    
    func fib(_ i: Int) {
        if arc4random_uniform(2) == 0 {
            sleep(1)
        } else {
            sleep(3)
        }
    }
    
    func completed() {
        print("Task completed")
    }
}

let app = BlackfishApp()

let task = FibTask()

app.use(middleware: Logger())

app.get("/") { (request, response) in
    
    let req = URLRequest(host: "127.0.0.1", path: "/api/v1/tutor/become", port: 3001, method: .POST)
    
    HTTP.perform(request: req) { (res, error) in
        response.render("views/index.html")
    }
}

app.listen(port: 5000) { error in
    print(error ?? "app listening on port \(app.port)")
}

