
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

final class MainQueue {

    let identifier: String

    var events: [() -> ()]

    var eventMutex: pthread_mutex_t

    var eventCondition: pthread_cond_t

    var running: Bool

    init(identifier: String) {

        self.identifier = identifier
        events = []
        eventMutex = pthread_mutex_t()
        eventCondition = pthread_cond_t()
        running = false
    }
}

extension MainQueue: DispatchQueue {

    func run() {

        running = true

        var conditionMutex = pthread_mutex_t()

        pthread_mutex_init(&eventMutex, nil)

        pthread_mutex_init(&conditionMutex, nil)

        pthread_cond_init (&eventCondition, nil)

        pthread_mutex_lock(&conditionMutex)

        while running {

            while events.count > 0 {
                pthread_mutex_lock(&eventMutex)
                let event = events.removeFirst()
                pthread_mutex_unlock(&eventMutex)
                event()
            }

            pthread_cond_wait(&eventCondition, &conditionMutex)
        }
    }

    func exit() {
        running = false
        pthread_cond_signal(&eventCondition)
    }
}
