import Blackfish

let app = Blackfish()

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
