import Foundation

let resourceDir: String = "Resources"

protocol Renderer {
    func render(path: String) throws -> [UInt8]
}

extension Renderer {
    
    func resourcePath(fileName: String) -> String {
        return resourceDir + "/" + fileName
    }
}

public class HTMLRenderer: Renderer {

    enum Error: ErrorType {
        case InvalidPath
    }
    
    func render(path: String) throws -> [UInt8]  {
        
        guard let fileBody = NSData(contentsOfFile: path) else {
            throw Error.InvalidPath
        }

        //TODO: Implement range
        var array = [UInt8](count: fileBody.length, repeatedValue: 0)
        fileBody.getBytes(&array, length: fileBody.length)
        return array
    }

}
