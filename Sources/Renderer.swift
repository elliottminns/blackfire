import Foundation

let resourceDir: String = "Resources"

enum RendererError: ErrorProtocol {
    case InvalidPath
    case ParseError
}

public protocol Renderer {
    
    func render(path: String, data: [String: Any]?) throws -> String
}

extension Renderer {
    
    private func resource(file: String) -> String {
        return resourceDir + "/" + file
    }
    
    func renderToBytes(path: String, data: [String: Any]?) throws -> [UInt8] {
        
        let body = try render(path: resource(file: path), data: data)
        
        return convertToBytes(data: body)
    }
    
    private func convertToBytes(data: String) -> [UInt8] {
        return [UInt8](data.utf8)
    }
    
    public func stringFromFile(path: String) throws -> String {
        guard let fileBody = NSData(contentsOfFile: path) else {
            throw RendererError.InvalidPath
        }
        
        guard let body = String(data: fileBody, encoding: NSUTF8StringEncoding) else {
            throw RendererError.ParseError
        }
        
        return body
    }
}

class HTMLRenderer: Renderer {

    func render(path: String, data: [String: Any]? = nil) throws -> String  {
        
        return try stringFromFile(path: path)
    }

}
