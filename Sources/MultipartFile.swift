
import Foundation
import Echo

#if os(Linux)
    import Glibc
#endif

enum FileError: ErrorType {
    case WriteError
}


public struct MultipartFile {

    public let name: String

    public let ext: String
    
    public let size: Int
    
    public let mimetype: String
    
    public let originalName: String
    
    public let fieldName: String
    
    public let path: String
    

}
