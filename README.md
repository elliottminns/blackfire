# Blackfish

A Node/Express Inspired Web Framework for Swift that works on iOS, OS X, and Ubuntu.

- [x] Insanely fast
- [x] Single Threaded
- [x] Beautiful syntax
- [x] Type safe

## Getting Started

You must have Swift 2.2 or later installed. You can learn more about Swift 2.2 at [Swift.org](http://swift.org)

### Work in Progress

This is a work in progress and will likely change frequently, pull requests are welcome!

## Server

Starting the server is as simple as express.

`main.swift`
```swift
import Blackfish

let app = Blackfish()

app.get("/") { request, response in
    response.send("Hello World!")
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
    response.send(text: 'Got a POST request')
});

//...start server
```

## Router

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


### JSON

Responding with JSON is easy.

```swift
app.get("version") { request, response in
	response.send(json: ["version": "1.0"])
}
```

This responds to all requests to `http://example.com/version` with the JSON dictionary `{"version": "1.0"}` and `Content-Type: application/json`.

### Views

You can also respond with HTML pages.

```swift
app.get("/") { request, response in
    response.render("index.html") 
}
```

Just put the file in the `Resources` folder at the root of your project and it will be served.

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

Vapor has been successfully tested on Ubuntu 14.04 LTS (DigitalOcean) and Ubuntu 15.10 (VirtualBox). 

To deploy to DigitalOcean, simply 

- Install Swift 2.2
	- `wget` the .tar.gz from Apple
	- Set the `export PATH` in your `~/.bashrc`
	- (you may need to install `binutils` as well if you see `ar not found`)
- Set Blackfish as a dependency of your project in your Package.swift
    ```swift
    dependencies:[
        // ...Previous dependencies
        .Package(url: "https://github.com/elliottminns/blackfish", majorVersion: 0)
    ]
    ```
- `cd` into the repository
	- Run `swift build`
	- Run `.build/debug/MyApp`
	- (you may need to run as `sudo` to use certain ports)
	- (you may need to install `ufw` to set appropriate ports)

## Attributions

This project is based on [Vapor](https://github.com/tannernelson/vapor) by Tanner Nelson. It uses compatibilty code from [NSLinux](https://github.com/johnno1962/NSLinux) by johnno1962.

Go checkout and star their repos.
