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
        if exists && !isDir {
//            FileSystem.readFile(atPath: filePath) { (data, error) in
//                guard let data = data else {
//                    print("Nexting");
//                    next();
//                    return
//                }
            
            if let fileBody = NSData(contentsOfFile: filePath) {
                var array = [UInt8](repeating: 0, count: fileBody.length)
                fileBody.getBytes(&array, length: fileBody.length)
                let ext = NSURL(fileURLWithPath: filePath).pathExtension ?? ""
                
                if (ext == "html") {
                    next()
                    return
                }
                
                response.status = .OK
                response.body = array
//                response.body = data.bytes
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
