import Foundation

public class Echo {

    static let instance = Echo()

    private var running = false

    let mainQueue: MainQueue
    let globalQueue: ConcurrentQueue

    private init() {
        mainQueue = MainQueue(identifier:"com.queue.main")
        globalQueue = ConcurrentQueue(identifier: "com.queue.global")
    }

    func begin() {
        if !running {
            running = true
            #if os(Linux)
            mainQueue.run()
            #else
            let resolution = 1.0;
            var isRunning: Bool = false
            repeat {
                let next = NSDate(timeIntervalSinceNow: resolution)
                isRunning = NSRunLoop.mainRunLoop()
                    .runMode(NSDefaultRunLoopMode, beforeDate: next)
            } while (running && isRunning)
            #endif

        }
    }

    func exit() {
        if running {
            running = false
            #if os(Linux)
            mainQueue.exit()
            #endif
        }
    }

    public class func begin() {
        Echo.instance.begin()
    }

    public class func beginEventLoop() {
        Echo.instance.begin()
    }

    public class func exit() {
        Echo.instance.exit()
    }
}
