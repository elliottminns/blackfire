import Foundation
import Echo

struct StaticFileMiddleware: Middleware {
    func handle(request: Request, response: Response, next: (() -> ())) {
        //check in file system
        let filePath = "Resources" + request.path
        
        let fileManager = NSFileManager.default()
        var isDir: ObjCBool = false
        
        let exists: Bool
#if os(Linux)
        exists = fileManager.fileExistsAtPath(filePath, isDirectory: &isDir)
#else
        exists = fileManager.fileExists(atPath: filePath, isDirectory: &isDir)
#endif
        if exists && !isDir {
            
            if let fileBody = NSData(contentsOfFile: filePath) {
                var array = [UInt8](repeating: 0, count: fileBody.length)
                fileBody.getBytes(&array, length: fileBody.length)
                let ext = NSURL(fileURLWithPath: filePath).pathExtension ?? ""
                
                response.status = .OK
                response.body = array
                response.contentType = .File(ext: ext)
                response.send()
            } else {
                next();
            }
        } else {
            next()
        }
    }
}
