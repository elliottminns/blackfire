import Blackfish

let app = BlackfishApp()

app.use(middleware: Logger())

app.get("/") { (request, response) in
    response.render("views/index.html")
}

app.listen(port: 3000) { error in
    print(error ?? "app listening on port \(app.port)")
}
