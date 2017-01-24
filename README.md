![Fire Image]
(http://i.imgur.com/1qR6Nl4.png)

# Blackfire
###### An extremely fast Swift web framework
![Swift Version](https://img.shields.io/badge/Swift-3.0-orange.svg)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
![License Apache](https://img.shields.io/badge/License-Apache-lightgrey.svg) 
![Plaforms](https://img.shields.io/badge/Platforms-Linux%20%7C%20macOS%20-blue.svg)


## 🔥 Getting Started

If you're familiar with express.js then Blackfire will be known to you. The most simple example of how to use can be seen below:

```swift
main.swift

import Blackfire

// Create a nice new 🔥 app for us to play with.
let app = Flame()

// Let's add a route to begin with.
app.get("/") { (req, res) in
  res.send(text: "Hello World")
}

app.start(port: 3000) { result in
  switch result {
    case .success:
      print("Server started on port 3000")
    case .failure(let error):
      print("Server failed with error: \(error)")
  }
}
```

```
$ curl localhost:3000 
Hello World%
```

## 🎁 Features

Blackfire has all the standard features of a typical minimal Web Framework, let's take a look at some of these.

### 🔱 Routing

Routing, as seen in the above example, takes place by assigning a handler to a method in your App

``` swift
app.get("/") { (req, res) in
  res.send(text: "I'm a GET request")
}
app.post("/users") { (req, res) in
  res.send(text: "I'm a POST request to /users")
}
app.delete("/all/files") { (req, res) in
  res.send(text: "I'm a DELETE request to /all/files ...wait")
}
app.put("/em/up") { (req, res) in
  res.send(text: "I'm a PUT request to /em/up Am I being robbed?")
}
```

This can become tedious if you have a lot of `/users/<something>` routes however, so we created the........

### 🐒 Router
###### Don't be scared that it's a monkey handling it, he had a pretty decent job interview on the whiteboard and seems to be doing ok.

The router object allows you to group routes together. For example

```swift
let users = Router()
users.get("/") { req, res in
  res.send(text: "Get me all the users")
}
users.post("/") { req, res in
  res.send(text: "Creating a new user")
}
users.get("/favourites") { req, res in
  res.send(json: ["food": "🍌"])
}

// Let's use the router to match for /users
app.use("/users", users)

```
```
$ curl localhost:3000/users
Get me all the users%
$ curl localhost:3000/users/favourites
{"food":"🍌"}%
```

Powerful stuff. 

## 📫 Request

The request or `req` object contains a bunch of helpful information that your handler may want to use:

These include:

* `request.params` A key value pair of `Strings` that are matched in the route
* `request.body` The raw body of the recieved request, in the form of a `String`
* `request.headers` A key value pair of `Strings` of the headers that appeared in the route
* `request.method` The method of this request, formed from the `HTTPMethod` enum.
* `request.path` The path of this request
* `request.httpProtocol` The protocol for this request.

## 📣 Response

The response or `res` object contains everything you need to return data back to the consumer

* `res.send(text: String)` Send back a basic text response in the form of `Content-Type: text/plain`
* `res.send(json: Any)` Send back some JSON, takes in a JSON parseable object. This method can fail if the object is not parseable
* `res.send(status: Int)` Send back a HTTP status with no body
* `res.send(html: String)` Send back some html with the header of `Content-Type: text/html`
* `res.send(error: String)` Sends back an error, setting the status to `500`.
* `res.headers` Set some headers to send back to the client

## 🐈 Threading

Threading is a contentious issue when it comes to web frameworks, the age old question of Single vs Multithreaded is enough to start a flame war. 

So let's fight the fire with fire and solve it once and for all.

### 👸 Queue Types

A Flame app can take a type of either `.serial` or `.concurrent`. These do exactly as they say on the tin and allow for either all requests to be handled via `DispatchQueue.main` or `DispatchQueue.global()`. 

### Why did we do this?

We think that giving you the power to choose which type you want for your app is a *good* thing. We're not sorry.

Just as an FYI, we chose to go with `.serial` as the default setting. It was a 50/50 chance we got it right. Good thing it can be changed.

### Example

```swift
// An app which handles only on the main thread.
let app = Flame(type: .serial)

// An app which handles on multiple concurrent threads.
let app = Flame(type: .concurrent)
```
