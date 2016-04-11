import Foundation
import Echo

struct StaticFileMiddleware: Middleware {
    func handle(request: Request, response: Response, next: (() -> ())) {
        //check in file system
        let filePath = "Resources" + request.path
        
        let fileManager = NSFileManager.defaultManager()
        var isDir: ObjCBool = false
        
        let exists: Bool
#if os(Linux)
        exists = fileManager.fileExistsAtPath(filePath, isDirectory: &isDir)
#else
        exists = fileManager.fileExists(atPath: filePath, isDirectory: &isDir)
#endif
        if exists {
            FileSystem.readFile(filePath) { data, error in
                if let data = data { 
                    response.status = .OK
                    response.body = data.bytes
                    response.contentType = .Text
                    response.send()
                } else {
                    next();
                }
            }
        } else {
            next()
        }
    }
}
