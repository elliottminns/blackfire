import Foundation

private class Node<T> {
    var nodes = [String: Node<T>]()
    var handler: [T] = []
}

class PathTree<T> {
    
    private var rootNode = Node<T>()
    
    func addHandler(handler: T, toPath path: String, overwrite: Bool) {
        let node = inflateTree(toPath: path)
        if overwrite {
            node.handler = [handler]
        } else {
            node.handler.append(handler)
        }
    }
    
    func paramsForPath(path: String) -> [String: String] {
        let result = findValue(path: path)
        return result.params
    }
    
    private func inflateTree(toPath path: String) -> Node<T> {
        var generator = segments(forPath: path)
        
        return inflateTree(withGenerator: &generator, node: &rootNode)
    }
    
    private func inflateTree(withGenerator generator: inout IndexingIterator<[String]>,
                                          node: inout Node<T>) -> Node<T> {
    
        var generator = generator
        
        if let pathSegment = generator.next() {
            
            if let _ = node.nodes[pathSegment] {
                return inflateTree(withGenerator: &generator, node: &node.nodes[pathSegment]!)
            }
            
            var nextNode = Node<T>()
            
            node.nodes[pathSegment] = nextNode
            
            return inflateTree(withGenerator: &generator, node: &nextNode)
        }
        
        return node
    }
    
    private func findNodes(forPath path: String) -> [(path: String, handlers: [T])]? {
        let comps = path.split(withCharacter: "/")
        let nodes = findNodes(withComps: comps, forNode: rootNode, withPart: "")
        return nodes
    }
    
    private func findNodes(withComps comps: [String],
                           forNode node: Node<T>,
                           withPart part: String) -> [(path: String, handlers: [T])]? {
        
        guard comps.count > 0 else {
            return [(path: part, handlers: node.handler)]
        }
        
        var comps = comps
        
        let next = comps.removeFirst()
        
        // Check for variables
        
        if let nextNode = node.nodes[next] {
            if let path = findNodes(withComps: comps, forNode: nextNode, withPart: next) {
                return [(path: part, handlers: node.handler)] + path
            } else {
                return nil
            }
            
        } else {
            let variables = node.nodes.filter { $0.0.characters.first == ":" }
            
            if variables.count > 0 {
                
                for variable in variables {
                    if let path = findNodes(withComps: comps, forNode: variable.value, withPart: variable.key) {
                        return [(path: part, handlers: node.handler)] + path
                    }
                    
                }
                
            }
                
            if let nextNode = node.nodes["*"] {
                if let path = findNodes(withComps: comps, forNode: nextNode, withPart: next) {
                    return [(path: part, handlers: node.handler)] + path
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
    }
    
    func findValue(path: String) -> (handlers: [T], params: [String: String]) {
        
        var params = [String:String]()
        var handlers: [T] = []
        
        if let nodePath = findNodes(forPath: path) {
            
            let pathComps = [""] + path.split(withCharacter: "/")
            
            for i in 0 ..< nodePath.count {
                let path = pathComps[i]
                let node = nodePath[i]
                if node.path.characters.first == ":" {
                    params[node.path] = path
                }
            }
            
            handlers = nodePath.last?.handlers ?? []
            
        }
        
        return (handlers: handlers, params: params)
    }
    
    
    func findValues(path: String) -> (handlers: [T], params: [String: String]) {
        
        var params = [String:String]()
        var handlers: [T] = []
        
        let nodePath = findAllNodes(forPath: path)
            
        let pathComps = [""] +  path.split(withCharacter: "/")
        
        for i in 0 ..< nodePath.count {
            let path = pathComps[i]
            let node = nodePath[i]
            if node.path.characters.first == ":" {
                params[node.path] = path
            }
            
            handlers += node.handlers
        }
        
        
        return (handlers: handlers, params: params)
    }
    
    func findAllNodes(forPath path: String) -> [(path: String, handlers: [T])] {
        let comps = path.split(withCharacter: "/")
        let nodes = findAllNodes(withComps: comps, forNode: rootNode, withPart: "")
        return nodes
    }
    
    private func findAllNodes(withComps comps: [String],
                              forNode node: Node<T>,
                              withPart part: String) -> [(path: String, handlers: [T])] {
        guard comps.count > 0 else {
            return [(path: part, handlers: node.handler)]
        }
        
        var comps = comps
        
        let next = comps.removeFirst()
        
        var paths: [(path: String, handlers: [T])] = []
        
        // Check for variables
        
        if let nextNode = node.nodes[next] {
            paths += findAllNodes(withComps: comps, forNode: nextNode, withPart: next)
            
        } else {
            let variables = node.nodes.filter { $0.0.characters.first == ":" }
            
            if variables.count > 0 {
                
                for variable in variables {
                    if let path = findNodes(withComps: comps, forNode: variable.value, withPart: variable.key) {
                        paths += [(path: part, handlers: node.handler)] + path
                    }
                }
            }
            
            if let nextNode = node.nodes["*"] {
                paths += findAllNodes(withComps: comps, forNode: nextNode, withPart: next)
            }
        }

        return [(path: part, handlers: node.handler)] + paths
        
    }
    
    private func segments(forPath path: String) -> IndexingIterator<[String]> {
        let pathSegments: [String] = (stripQuery(path: path)).split(withCharacter: "/")
        return pathSegments.makeIterator()
    }
    
    private func stripQuery(path: String) -> String {
        
        if let path = path.split(withCharacter: "?").first {
            return path
        }
        return path
    }
}
