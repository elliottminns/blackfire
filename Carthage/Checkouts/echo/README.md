# Echo

Echo is a simple way to create an event loop and use GCD in Swift for Linux and OSX

## How to use?

Using Echo is simple, to start the main run loop, just call:

```swift
Echo.beginEventLoop()
```

or

```swift
Echo.begin()
```

When you want to exit the loop, just call `exit`

```swift
Echo.exit()
```

## How to use GCD?

Using GCD is the same as with Mac OS X (With limited current features)

```swift
main.swift
```

```swift
import Echo

dispatch_async(dispatch_get_global_queue(0, 0)) {
    for i in 0 ..< 1000 {
        dispatch_async(dispatch_get_main_queue()) {
            print(i)
        }
    }

    dispatch_async(dispatch_get_main_queue()) {
        Echo.exit()
    }
}

Echo.begin()

```

The above code snippet will print all the numbers on the main loop whilst looping in the global queue.

## What is it used for?

- [Blackfish](http://github.com/elliottminns/blackfish)

- [Orca](http://github.com/elliottminns/orca) (Coming soon...)

## Is that it?

Yep, it's that simple.

Please feel free to fork and extend to the rest of GCD's functions for Linux
