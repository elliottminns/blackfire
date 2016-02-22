

class ParameterManager {
    
    typealias Handler = (request: Request, response: Response, param: String, next: () -> ()) -> ();
    
    private var handlers: [String: [Handler]]
    
    init() {
        handlers = [:]
    }
    
    func addHandler(handler: Handler, forParam param: String) {
        if handlers[param] == nil {
            handlers[param] = []
        }
        handlers[param]?.append(handler)
    }
    
    func handlersForParams(params: [String: String]) -> [String: [Handler]] {
        
        var handlers = [String: [Handler]]()
        
        for (key, _) in params {
            
            if let h = self.handlers[key] {
                handlers[key] = h
            }
        }
        
        return handlers
    }
    
}
