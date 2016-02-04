
class MiddlewareManager {
    
    private var middleware: [Middleware]
    
    private class Node {
        var nodes = [String: Node]()
        var handler: Middleware.Handler? = nil
    }
    
    private var rootNode: Node
    
    init() {
        middleware = []
        rootNode = Node()
    }
    
    func register(middleware middleware: Middleware) {
        var pathSegments = [String]()
        
        if let path = middleware.path {
            pathSegments = stripQuery(path).split("/")
        }
        
        pathSegments.insert("*", atIndex: 0)
        
        var pathSegmentsGenerator = pathSegments.generate()
        
        inflate(&rootNode, generator: &pathSegmentsGenerator).handler = middleware.handler
    }
    
    func route(method: Request.Method?, path: String) -> [Middleware.Handler] {
        
        let pathSegments: [String]
        
        if let method = method {
            pathSegments = (method.rawValue + "/" + stripQuery(path)).split("/")
        } else {
            pathSegments = ("*/" + stripQuery(path)).split("/")
        }
        
        var pathSegmentsGenerator = pathSegments.generate()
        
        var params = [String:String]()
        
        return findHandlers(&rootNode, params: &params, generator: &pathSegmentsGenerator,
            handlers: []).reverse()
    }
    
    private func inflate(inout node: Node, inout generator: IndexingGenerator<[String]>) -> Node {
        
        if let pathSegment = generator.next() {
            
            if let _ = node.nodes[pathSegment] {
                return inflate(&node.nodes[pathSegment]!, generator: &generator)
            }
            
            var nextNode = Node()
            
            node.nodes[pathSegment] = nextNode
            
            return inflate(&nextNode, generator: &generator)
        }
        
        return node
    }
    
    private func findHandlers(inout node: Node, inout params: [String: String],
        inout generator: IndexingGenerator<[String]>, handlers: [Middleware.Handler]) -> [Middleware.Handler] {
            
            var handlers = handlers
            
            guard let pathToken = generator.next() else {
                return handlers
            }
            
            let variableNodes = node.nodes.filter { $0.0.characters.first == ":" }
            
            if let variableNode = variableNodes.first {
                params[variableNode.0] = pathToken
                return findHandlers(&node.nodes[variableNode.0]!, params: &params, generator: &generator, handlers: handlers)
            }
            
            if let handlerNode = node.nodes[pathToken] {
                
                if let handler = handlerNode.handler {
                    handlers.append(handler)
                }
                
                let nextHandlers = findHandlers(&node.nodes[pathToken]!, params: &params, generator: &generator, handlers: handlers)
                
                return nextHandlers
            }
            
            if let handlerNode = node.nodes["*"] {
                
                if let handler = handlerNode.handler {
                    handlers.append(handler)
                }
                let nextHandlers = findHandlers(&node.nodes["*"]!, params: &params, generator: &generator,
                    handlers: handlers)
                return nextHandlers
            }
            
            return handlers
    }
    
    private func stripQuery(path: String) -> String {
        if let path = path.split("?").first {
            return path
        }
        return path
    }
    
    
}