//
//  MultipartFile.swift
//  blackfish
//
//  Created by Elliott Minns on 03/02/2016.
//  Copyright © 2016 Elliott Minns. All rights reserved.
//

import Foundation
#if os(Linux)
    import Glibc
#endif

enum FileError: ErrorType {
    case WriteError
}

struct MultipartFile {
    
    let name: String
    
    let data: [UInt8]
    
    func saveToTemporaryDirectory(filename: String, completion: ((path: String?, error: ErrorType?) -> Void)) {
        let path = NSTemporaryDirectory() + "\(filename)"
        saveToPath(path, completion: completion)
    }
    
    func saveToPath(path: String, completion: ((path: String?, error: ErrorType?) -> Void)) {
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
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