//
//  Tree.swift
//  blackfish
//
//  Created by Elliott Minns on 05/02/2016.
//  Copyright © 2016 Elliott Minns. All rights reserved.
//

import Foundation

private class Node<T> {
    var nodes = [String: Node<T>]()
    var handler: T? = nil
}

class PathTree<T> {
    
    private var rootNode = Node<T>()
    
    func addHandler(handler: T, toPath path: String) {
        inflateTreeToPath(path).handler = handler
    }
    
    private func inflateTreeToPath(path: String) -> Node<T> {
        var generator = segmentsForPath(path)
        
        return inflateTreeWithGenerator(&generator, node: &rootNode)
    }
    
    private func inflateTreeWithGenerator(inout generator: IndexingGenerator<[String]>, inout node: Node<T>) -> Node<T> {
    
        var generator = generator
        
        if let pathSegment = generator.next() {
            
            if let _ = node.nodes[pathSegment] {
                return inflateTreeWithGenerator(&generator, node: &node.nodes[pathSegment]!)
            }
            
            var nextNode = Node<T>()
            
            node.nodes[pathSegment] = nextNode
            
            return inflateTreeWithGenerator(&generator, node: &nextNode)
        }
        
        return node
    }
    
    func findValue(path: String) -> T? {
        var generator = segmentsForPath(path)
        
        var params = [String:String]()
        
        return findValues(&rootNode, params: &params, generator: &generator, values: [], exclude: true).first
    }
    
    func findValues(path: String) -> [T] {
        
        var generator = segmentsForPath(path)
        
        var params = [String:String]()
        
        return findValues(&rootNode, params: &params, generator: &generator, values: [])
    }
    
    private func findValues(inout node: Node<T>, inout params: [String: String], inout generator: IndexingGenerator<[String]>, values: [T], exclude: Bool = false) -> [T] {
            
            var values = values
            
            guard let pathToken = generator.next() else {
                if exclude {
                    if let handler = node.handler {
                        values.append(handler)
                    }
                }
                return values
            }
            
            let variableNodes = node.nodes.filter { $0.0.characters.first == ":" }
            
            if let variableNode = variableNodes.first {
                params[variableNode.0] = pathToken
                return findValues(&node.nodes[variableNode.0]!, params: &params, generator: &generator, values: values)
            }
            
            if let handlerNode = node.nodes[pathToken] {
                
                if !exclude {
                    if let handler = handlerNode.handler {
                        values.append(handler)
                    }
                }
                
                let nextValues = findValues(&node.nodes[pathToken]!, params: &params, generator: &generator, values: values)
                
                return nextValues
            }
            
            if let handlerNode = node.nodes["*"] {
                if !exclude {
                    if let value = handlerNode.handler {
                        values.append(value)
                    }
                }
                let nextValues = findValues(&node.nodes["*"]!, params: &params, generator: &generator,
                    values: values)
                return nextValues
            }
            
            return values
    }
    
    private func segmentsForPath(path: String) -> IndexingGenerator<[String]> {
        let pathSegments: [String] = (stripQuery(path)).split("/")
        return pathSegments.generate()
    }
    
    private func stripQuery(path: String) -> String {
        
        if let path = path.split("?").first {
            return path
        }
        return path
    }
}