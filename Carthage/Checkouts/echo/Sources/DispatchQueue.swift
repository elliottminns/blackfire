#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

enum ConcurrencyType {
    case Serial
    case Concurrent
}

public protocol DispatchQueue: class {

    var identifier: String { get }

    var events: [() -> ()] { get set }

    init(identifier: String)

    var eventMutex: pthread_mutex_t { get set }

    var eventCondition: pthread_cond_t { get set }

    func run()
}

extension DispatchQueue {

    func addEvent(event: () -> ()) {
        pthread_mutex_lock(&eventMutex)
        events.append(event)
        pthread_mutex_unlock(&eventMutex)
        pthread_cond_signal(&eventCondition)
    }

    func runBlock(block: () -> (), inout onThread thread: pthread_t) {
        let holder = Unmanaged.passRetained(pthreadBlock(block: block))

        let pointer = UnsafeMutablePointer<Void>(holder.toOpaque())

        if pthread_create(&thread, nil, pthreadRunner, pointer ) == 0 {
            pthread_detach(thread)
        } else {
            print("pthread_create() error")
        }
    }

}

private class pthreadBlock {

    let block: () -> ()

    init( block: () -> () ) {
        self.block = block
    }
}

private func pthreadRunner( arg: UnsafeMutablePointer<Void> ) -> UnsafeMutablePointer<Void> {
    let unmanaged = Unmanaged<pthreadBlock>.fromOpaque( COpaquePointer( arg ) )
    unmanaged.takeUnretainedValue().block()
    unmanaged.release()
    return arg
}
