#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

#if os(Linux)
public let DISPATCH_QUEUE_CONCURRENT = 200
public let DISPATCH_QUEUE_SERIAL = 201

public typealias dispatch_queue_t = DispatchQueue

public func dispatch_queue_create(name: String,
    _ type: Int ) -> dispatch_queue_t {

    let queue: DispatchQueue

    if type == DISPATCH_QUEUE_SERIAL {
        queue = SerialQueue(identifier: name)
    } else {
        queue = ConcurrentQueue(identifier: name)
    }

    return queue
}

public let DISPATCH_QUEUE_PRIORITY_HIGH = 0,
    DISPATCH_QUEUE_PRIORITY_LOW = 0,
    DISPATCH_QUEUE_PRIORITY_BACKGROUND = 0

public func dispatch_get_global_queue( type: Int, _ flags: Int ) -> dispatch_queue_t {
    return Echo.instance.globalQueue
}

public func dispatch_sync( queue: Int, _ block: () -> () ) {
    block()
}

public func dispatch_async(queue: dispatch_queue_t, _ block: () -> ()) {
    queue.addEvent(block)
}

public let DISPATCH_TIME_NOW = 0, NSEC_PER_SEC = 1_000_000_000

public func dispatch_time( now: Int, _ nsec: Int64 ) -> Int64 {
    return nsec
}

public func dispatch_after(delay: Int64, _ queue: dispatch_queue_t,
                           _ block: () -> ()) {
    dispatch_async(queue, {
        sleep(UInt32(Int(delay)/NSEC_PER_SEC))
        block()
    })
}

public func dispatch_get_main_queue() -> dispatch_queue_t {
    return Echo.instance.mainQueue
}

#endif
