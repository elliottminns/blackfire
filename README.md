#

![Blackfish](http://i.imgur.com/UAcoXzu.png)

A Node/Express Inspired Web Framework for Swift that works on iOS, OS X, and Ubuntu.

![Travis Badge](https://travis-ci.org/elliottminns/blackfish.svg?branch=master)

- [x] Insanely fast
- [x] Single Threaded
- [x] Beautiful syntax
- [x] Type safe
- [x] Powered by [Echo](https://github.com/elliottminns/echo)
- [x] Running on [Heroku](https://blackfish-example.herokuapp.com)

Table of Contents
=================

* [Getting Started](#getting-started)
  * [Work in Progress](#work-in-progress)
* [Server](#server)
* [Routing](#routing)
  * [Router](#router)
  * [Controller](#controller)
  * [JSON](#json)
  * [Views](#views)
  * [Response](#response)
  * [Public](#public)
* [Database](#database)
* [Request](#request)
  * [Middleware](#middleware)
  * [Multipart](#multipart)
  * [Session](#session)
* [Deploying](#deploying)
  * [Heroku](#heroku)
  * [DigitialOcean](#digitalocean)

## Getting Started

You must have Swift 2.2 or later installed. You can learn more about Swift 2.2 at [Swift.org](http://swift.org)

Blackfish is tested using the latest Swift **Development** snapshots, with current testing using snapshot [February 8, 2016](https://swift.org/download/)

### Work in Progress

This is a work in progress and will likely change frequently, pull requests are welcome!

The [example project](https://github.com/elliottminns/blackfish-example) shows how easy it is to begin, and has an instance running on Heroku [here](https://blackfish-example.herokuapp.com)

## Server

Starting the server is as simple as express.

`main.swift`
```swift
import Blackfish

let app = BlackfishApp()

app.get("/") { request, response in
    response.send(text: "Hello World!")
}

app.listen(port: 3000) { error in
    if error == nil {
        print("Example app listening on port 3000")
    }
}
```

If you are having trouble connecting, make sure your ports are open. Check out `apt-get ufw` for simple port management.

## Routing

Routing in Blackfish is simple and very similar to Express.

`main.swift`
```swift
app.get("/welcome") { request, response in
	response.send(text: "Hello")
}

app.post('/') { request, response in
    // POST data
    print(request.data)
    response.send(text: 'Got a POST request')
});

//...start server
```

### Router

You can also create a Router object which will allow you to define multiple routes with a prefix.

```swift
let router = Router()

router.get("/") { request, response in
    response.send(text: "Bird is the word")
}

router.get("/about") { request, response in
    response.send(text: "Don't you know, about the bird?")
}

app.use(path: "/birds", router: router)

// ...start server
```

Navigating to `http://example.com/birds` will show a page with `Bird is the word` and navigating to `http://example.com/birds/about` will show a page with `"Don't you know, about the bird?"`.

### Controller

You can also use controllers to define your paths. All you need to do is extend from the `Controller` protocol and implement your routes in `func routes(router: Router)` to the router object passed in:

```
MyController.swift
```

```swift
class MyController: Controller {
    
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
```

Routes can be either functions with the correct parameters or Route.Handler objects themselves.

Then we just need to add the controller to the server:

```
main.swift
```

```swift
let app = BlackfishApp()

app.use(path: "/test", controller: MyController())

app.listen(port: 3000) { error in
    if error == nil {
        print("App listening on port 3000")
    } else {
        print("Error")
    }
}
```

Now our `/test` and `/test/update` paths will be correct populated

### JSON

Responding with JSON is easy.

```swift
app.get("version") { request, response in
	response.send(json: ["version": "1.0"])
}
```

This responds to all requests to `http://example.com/version` with the JSON dictionary `{"version": "1.0"}` and `Content-Type: application/json`.

Requesting with JSON is also supported:

```swift
app.post("/") { request, response in 

    for (key, value) in request.data {
         print("\(key): \(value)")
    }
    
    response.send(text: "Hello")
}
```

```
$ curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d "{'json':{'data': 1}}" http://127.0.0.1:3000

$ "json: ["data": 1]"
```
### Views

You can also respond with HTML pages.

```swift
app.get("/") { request, response in
    response.render("index.html")
}
```

Just put the file in the `Resources` folder at the root of your project and it will be served.

You can also create your own renderers to use within Blackfish. A renderer for [Stencil](https://github.com/kylef/Stencil) is already available here [Blackfish Stencil](https://github.com/elliottminns/blackfish-stencil).

```
index.stencil
```

```html
<html>
    <h1>{{ title }}</h1>
</html>
```

```swift
app.get("/") { request, response in
    res.render("index.stencil", data:["title": "Hello world"])
}
```

### Response

A manual response can be returned if you want to set something like `cookies`.

```swift
Route.get("cookie") { request, response in
    response.status = .OK
    response.text = "Cookie was set"
	response.cookies["test"] = "123"
	response.send()
}
```

The Status enum above (`.OK`) can be one of the following.

```swift
public enum Status {
    case OK, Created, Accepted
    case MovedPermanently
    case BadRequest, Unauthorized, Forbidden, NotFound
    case ServerError
    case Unknown
    case Custom(Int)
}
```

Or something custom.

```swift
let status: Status = .Custom(420) //https://dev.twitter.com/overview/api/response-codes
```

### Public

All files put in the `Public` folder at the root of your project will be available at the root of your domain. This is a great place to put your assets (`.css`, `.js`, `.png`, etc).

## Database

Blackfish works best with any event based based database, especially if powered by [Echo](https://github.com/elliottminns/echo).

Currently, [Orca](https://github.com/elliottminns/orca) is recommended, which allows for asynchronous, non-blocking data persistence.

Orca currently supports

- [SQLite](https://github.com/elliottminns/orca-sqlite)
- [MongoDB](https://github.com/elliottminns/orca-mongodb)


## Request

Every route call gets passed a `Request` object. This can be used to grab query and path parameters.

This is a list of the properties available on the request object.

```swift
let method: Method
var parameters: [String: String] //URL parameters like id in user/:id
var data: [String: String] //GET or POST data
var cookies: [String: String]
var session: Session
```

### Middleware

Similar to Express, Blackfish provides Middleware which can be used to extend the request stack.

You can either create a middleware class that conforms to the `Middleware` protocol, or pass a closure in to the Blackfish instance.

Below is an example of a validation Middleware conforming class, that validates every request before passing it down the stack.

```swift

class Validator: Middleware {

    func handle(request: Request, response: Response, next: () -> ()) {
    
    // Some validation logic
    if validator.validate(request) {

        // Go to the next call in the stack.
        next()

    } else {

        // Return an error and don't call anything else in the stack.
        response.send(error: "Request was unauthorized")
    }	
}

app.use(middleware: Validator()) 

```

You can also use middleware on a path which will add it to that path and further on.

```swift

let userDetail = { (request, response, next) in 
    let user = findUserById(request.data["userId"])
    request.data["user"] = user
    next()
}

app.use(path: "/user", middleware: userDetail)
app.use(path: "/dashboard", middleware: Validator())

```

Middleware is a powerful feature of Blackfish that can open up endless possibilities.

### Multipart

To allow multipart parsing of files and other data from `enctype="multitype/form-data" you need to add the `Multiparser` middleware to the stack:

```swift
app.use(middleware: Multiparser())
```

Following this, you can access all multipart text input under `request.data` and files under `request.files`.

example:

```swift
app.use(middleware: Multiparser())

app.post("/") { request, response in 
   print(request.data["name"])
   print(request.files["images"].first)
}
```

### Session

Sessions will be kept track of using the `blackfish-session` cookie. The default (and currently only) session driver is `.Memory`.

```swift
if let name = request.session.data["name"] {
	//name was in session
}

//store name in session
request.session.data["name"] = "Blackfish"
```

## Deploying

### Heroku

The [Blackfish Example](https://github.com/elliottminns/blackfish-example) app is successfully running on Heroku [here](https://blackfish-example.herokuapp.com)

To set up on Heroku, use the [Swift Heroku Buildpack](https://github.com/kylef/heroku-buildpack-swift) by Kyle Fuller.

Instructions for setting up are:

Create a Procfile at the same level as your Package.swift


```
./Procfile
```

```
web: <AppName> --port=$PORT
```

Then

```
$ heroku create --buildpack https://github.com/kylef/heroku-buildpack-swift.git

$ git push heroku master
```

And you're good!

For more information, see the [Blackfish Example](https://github.com/elliottminns/blackfish-example) project.

### DigitalOcean

Blackfish has been successfully tested on Ubuntu 14.04 LTS (DigitalOcean) and Ubuntu 15.10 (VirtualBox).

To deploy to DigitalOcean, simply

- Install Swift 2.2
	- `wget` the .tar.gz from Apple
	- Set the `export PATH` in your `~/.bashrc`
	- (you may need to install `binutils` as well if you see `ar not found`)
- Set Blackfish as a dependency of your project in your Package.swift
    ```swift
    dependencies:[
        // ...Previous dependencies
        .Package(url: "https://github.com/elliottminns/blackfish.git", majorVersion: 0)
    ]
    ```
- `cd` into the repository
	- Run `swift build`
	- Run `.build/debug/MyApp`
	- (you may need to run as `sudo` to use certain ports)
	- (you may need to install `ufw` to set appropriate ports)
