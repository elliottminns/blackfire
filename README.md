![Fire Image]
(http://i.imgur.com/1qR6Nl4.png)


# Blackfire
An extremely fast Swift web framework

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

