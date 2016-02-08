
import Foundation
#if os(Linux)
    import Glibc
#endif

enum FileError: ErrorType {
    case WriteError
}

public struct MultipartFile {
    
    public let name: String
    
    public let data: [UInt8]
    
    public func saveToTemporaryDirectorySync(filename: String, completion: ((path: String?, error: ErrorType?) -> Void)) {
        self.saveToTemporaryDirectory(filename, completion: completion, synchronous: true)
    }
    
    public func saveToTemporaryDirectory(filename: String, completion: ((path: String?, error: ErrorType?) -> Void), synchronous: Bool = false) {
        
        #if os(Linux)
            let path = "/var/tmp/" + filename
        #else
            let path = NSTemporaryDirectory() + "\(filename)"
        #endif
    
        saveToPath(path, completion: completion, synchronous: synchronous)
    }
    
    public func saveToPath(path: String, completion: ((path: String?, error: ErrorType?) -> Void),
                           synchronous: Bool = false) {
    
        let queue = synchronous ? dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) : DISPATCH_CURRENT_QUEUE_LABEL
        dispatch_async(queue) {
            
            let raw = NSData(bytesNoCopy: UnsafeMutablePointer<Void>(self.data),
                length: self.data.count * sizeof(UInt8), freeWhenDone: false)
            
            if raw.writeToFile(path, atomically: true) {
                
                completion(path: path, error: nil)
                
            } else {
                
                completion(path: nil, error: FileError.WriteError)
            }
        }
    }
    
}