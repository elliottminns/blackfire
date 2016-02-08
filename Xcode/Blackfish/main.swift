//
//  main.swift
//  blackfish
//
//  Created by Elliott Minns on 02/02/2016.
//  Copyright © 2016 Elliott Minns. All rights reserved.
//

import Foundation

let app = Blackfish()

let router = Router()

router.get("/") { (request, response) in
    response.send(text: "Bird is the word")
}

router.get("/about") { (request, response) in
    response.send(text: "Don't you know, about the bird?")
}

app.use(path: "/birds", router: router)

app.get("/long") { request, response in
    response.send(html: "<h1>Hello</h1>")
}

app.get("/") { (request, response) -> Void in
    response.render("som-trainer.html")
}

let clock = Middleware { (request, response, next) in
    print("The time is \(NSDate())")
    next()
}

let logger = Middleware { (request, response, next) in
    print("Recieved a request for path: \(request.path)")
    next()
}

app.use(middleware: clock)
app.use(middleware: logger)

app.post("/") { (request, response) in
    
    response.render("som-trainer.html")
}

app.get("/test") { (request, response) in
    
    response.send(json: ["Hello": "World"])
}

app.listen(port: 3000) { err in
    
    if err == nil {
        print("Server started")
    }
    
}
