#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

final class SerialQueue {
    
    let identifier: String
    
    var events: [() -> ()]
    
    var eventMutex: pthread_mutex_t
    
    var eventCondition: pthread_cond_t
    
    var thread: pthread_t
    
    init(identifier: String) {
        
        self.identifier = identifier
        self.events = []
        self.eventMutex = pthread_mutex_t()
        self.eventCondition = pthread_cond_t()
        self.thread = pthread_t()
        run()
    }
}

extension SerialQueue: DispatchQueue {
    
    func run() {
        
        let block = {
            var conditionMutex = pthread_mutex_t()
        
            pthread_mutex_init(&self.eventMutex, nil)
            
            pthread_mutex_init(&conditionMutex, nil)
            
            pthread_cond_init (&self.eventCondition, nil)
            
            pthread_mutex_lock(&conditionMutex)
            
            while true {
                
                while self.events.count > 0 {
                    pthread_mutex_lock(&self.eventMutex)
                    let event = self.events.removeFirst()
                    pthread_mutex_unlock(&self.eventMutex)
                    event()
                }

                pthread_cond_wait(&self.eventCondition, &conditionMutex)
            }
        }
        
        self.runBlock(block, onThread: &thread)
    }
}
