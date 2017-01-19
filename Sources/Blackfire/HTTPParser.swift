
import Foundation

struct ParserError: Error {
    let problemArea: String
    let message: String
}

struct HTTPParser {
    
    let data: Data
    
	init(data: Data) {
		self.data = data
	}

    func parse() throws -> HTTPRequest? {
        
        let raw = try self.data.toString()
        
        guard raw.contains("\r\n\r\n") else {
            return nil
        }

        var lines = raw.components(separatedBy: "\r\n")
        let firstLine = lines.removeFirst()
        let route = try loadRoute(line: firstLine)
        let headers = loadHeaders(&lines)
        let body = lines.last ?? ""
        
        return HTTPRequest(headers: headers, method: route.method, body: body,
                           path: route.path, httpProtocol: route.httpProtocol)
    }
    
    func loadRoute(line: String) throws -> (method: HTTPMethod, path: String, httpProtocol: String) {
        let comps = line.components(separatedBy: " ")
        
        guard let methodString = comps.first,
            let httpProtocol = comps.last,
            comps.count == 3 else {
                throw ParserError(problemArea: line,
                                  message: "Missing a part of the route")
        }
        
        guard let method = HTTPMethod(string: methodString) else {
            throw ParserError(problemArea: "Method", message: "Method is unknown for type: \(methodString)")
        }
        
        return (method: method, path: comps[1], httpProtocol: httpProtocol)
    }
	
    func loadHeaders(_ lines: inout [String]) -> [String: String] {
        var headers: [String: String] = [:]
        
        var currentLine = lines.removeFirst()
        
        repeat {
            
            let comps = currentLine.components(separatedBy: ": ")
            
            if comps.count == 2 {
                
                headers[comps[0]] = comps.last
            }
            
            currentLine = lines.removeFirst()
        } while currentLine.utf8.count > 0
        
        return headers
    }
}
