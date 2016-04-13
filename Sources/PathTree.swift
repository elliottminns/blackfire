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
    
    func findValue(path: String) -> (handler: T?, params: [String: String]) {
        var generator = segments(forPath: path)
        
        var params = [String:String]()
        
        let handler = findValues(node: &rootNode, params: &params, generator: &generator, values: [], exclude: true).first
        
        return (handler: handler, params: params)
    }
    
    func findValues(path: String) -> (handlers: [T], params: [String: String]) {
        
        var generator = segments(forPath: path)
        
        var params = [String:String]()
        let handlers = findValues(node: &rootNode, params: &params, generator: &generator, values: [])
        return (handlers: handlers, params: params)
    }
    
    private func findValues(node: inout Node<T>, params: inout [String: String], 
                            generator: inout IndexingIterator<[String]>, 
                            values: [T], exclude: Bool = false) -> [T] {
            
            var values = values
            
            guard let pathToken = generator.next() else {
                if exclude {
                    values.append(contentsOf: node.handler)
                }
                return values
            }
            
            let variableNodes = node.nodes.filter {
                $0.0.characters.first == ":"
            }
            
            if let variableNode = variableNodes.first {
                params[variableNode.0] = pathToken
                return findValues(node: &node.nodes[variableNode.0]!, params: &params, generator: &generator, values: values, exclude: exclude)
            }
            
            if let handlerNode = node.nodes[pathToken] {
                
                if !exclude {
                    values.append(contentsOf: handlerNode.handler)
                }
                
                let nextValues = findValues(node: &node.nodes[pathToken]!, params: &params, generator: &generator, values: values, exclude: exclude)
                
                return nextValues
            }
            
            if let handlerNode = node.nodes["*"] {
                if !exclude {
                    values.append(contentsOf: handlerNode.handler)
                }
                let nextValues = findValues(node: &node.nodes["*"]!, params: &params, generator: &generator,
                    values: values, exclude: exclude)
                return nextValues
            }
            
            return values
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
