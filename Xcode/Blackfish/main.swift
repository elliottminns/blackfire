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

let request = URLRequest(host: "squior.io", path: "/", port: 80)

let connection = URLConnection(request: request)

app.use(middleware: Logger())

app.get("/") { (request, response) in
    response.render("views/index.html")
}

app.listen(port: 5000) { error in
    print(error ?? "app listening on port \(app.port)")
}

