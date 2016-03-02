import Foundation
import Echo
import Vaquita

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public class Multiparser: Middleware {
    
    let multipartFormIdentifier = "multipart/form-data"
    let boundaryIdentifier = "boundary"
    
    let directory: String
    
    public init(directory: String? = nil) {
        #if os(Linux)
            srand(UInt32(time(nil)))
        #endif
        
        if let directory = directory {
            self.directory = directory
        } else {
            #if os(Linux)
            self.directory = "/var/tmp/"
            #else
            self.directory = NSTemporaryDirectory()
            #endif
        }
    }
    
    
    func writeData(data: [UInt8], toPath path: String) throws {
        let raw = NSData(bytesNoCopy: UnsafeMutablePointer<Void>(data),
                         length: data.count * sizeof(UInt8), freeWhenDone: false)

        try raw.writeToFile(path, options: .DataWritingAtomic)
    }
    
    public func handle(request: Request, response: Response, next: (() -> ())) {
        
        guard let contentTypeHeader = request.headers["content-type"] else {
            next()
            return
        }
        
        let contentTypeHeaderTokens = contentTypeHeader.split(";").map { $0.trim() }
        guard let contentType = contentTypeHeaderTokens.first where contentType == "multipart/form-data" else {
            next()
            return
        }
        
        var boundary: String? = nil
        
        for token in contentTypeHeaderTokens {
            
            let tokens = token.split("=")
            
            if let key = tokens.first where key == "boundary" && tokens.count == 2 {
                boundary = tokens.last
            }
        }
        
        if let boundary = boundary where boundary.utf8.count > 0 {
            
            dispatch_async(dispatch_get_global_queue(0, 0), {
            
                let multiparts = self.parseMultiPartFormData(request.body, boundary: "--\(boundary)")
                
                for multipart in multiparts {
                    if let fileName = multipart.fileName,
                        let ext = fileName.split(".").last,
                        let fieldName = multipart.name {
                        
                        let name = self.randomStringWithLengthAndTime(10)
                        let size = multipart.body.size
                        let mimetype = MimeType.forExtension(ext)
                        
                        let path = self.directory + name + "." + ext
                        do {
                            try Vaquita.writeDataSync(multipart.body, toFilePath: path)

                            let file = MultipartFile(name: name, ext: ext, size: size,
                                mimetype: mimetype, originalName: fileName,
                                fieldName: fieldName, path: path)
                            
                            if request.files[fieldName] == nil {
                                
                                request.files[fieldName] = []
                            }
                            
                            request.files[fieldName]!.append(file)
                        } catch let errorMessage {
                            print("Boundry Error: \(errorMessage)")
                        }
                        
                    } else {
                        if let value = multipart.value, let name = multipart.name {
                            request.data[name] = value
                        }
                    }
                }
                
                next()
            })
        } else {
            next()
        }
    }
    
    func randomStringWithLengthAndTime(length: Int) -> String {
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".characters
        
        let randomString: String
        
        let lettersLength = UInt32(letters.count)
        
        let randomCharacters = (0 ..< length).map { i -> String in
            #if os(Linux)
                let offset = Int(UInt32(rand()) % UInt32(lettersLength))
            #else
                let offset = Int(arc4random_uniform(lettersLength))
            #endif
            let c = letters[letters.startIndex.advancedBy(offset)]
            return String(c)
        }
        
        randomString = randomCharacters.joinWithSeparator("")
        
        let time = "\(NSDate().timeIntervalSinceReferenceDate)"
        
        return "\(randomString)\(time.split(".").joinWithSeparator(""))"
    }
    
    struct MultiPart {
        
        let headers: [String: String]
        
        let body: Data
        
        var name: String? {
            return valueFor("content-disposition", parameterName: "name")?.unquote()
        }
        
        var fileName: String? {
            return valueFor("content-disposition", parameterName: "filename")?.unquote()
        }
        
        var value: String? {
            let string: String?
            do {
                string = try body.toString()
            } catch {
                string = nil
            }
            
            if string?.characters.count > 0 {
                return string
            } else {
                return nil
            }
        }
        
        private func valueFor(headerName: String, parameterName: String) -> String? {
            
            return headers.reduce([String]()) { (currentResults: [String],
                header: (key: String, value: String)) -> [String] in
                
                guard header.key == headerName else {
                    return currentResults
                }
                let headerValueParams = header.value.split(";").map { $0.trim() }
                return headerValueParams.reduce(currentResults, combine: { (results:[String], token: String) -> [String] in
                    let parameterTokens = token.split(1, separator: "=")
                    if parameterTokens.first == parameterName, let value = parameterTokens.last {
                        return results + [value]
                    }
                    return results
                })
                }.first
        }
    }
    
    private func parseMultiPartFormData(data: Data, boundary: String) -> [MultiPart] {
        
        var generator = data.bytes.generate()
        
        var result = [MultiPart]()
        
        while let part = nextMultiPart(&generator, boundary: boundary, isFirst: result.isEmpty) {
            
            result.append(part)
            
        }
        return result
    }
    
    private func nextMultiPart(generator: inout IndexingGenerator<[UInt8]>,
                                     boundary: String, isFirst: Bool) -> MultiPart? {
        if isFirst {
            guard nextMultiPartLine(&generator) == boundary else {
                return nil
            }
        } else {
            nextMultiPartLine(&generator)
        }
        
        var headers = [String: String]()
        
        while let line = nextMultiPartLine(&generator) where !line.isEmpty {
            
            let tokens = line.split(":")
            
            if let name = tokens.first, value = tokens.last where tokens.count == 2 {
                headers[name.lowercaseString] = value.trim()
            }
            
        }
        
        guard let body = nextMultiPartBody(&generator, boundary: boundary) else {
            return nil
        }
        
        return MultiPart(headers: headers, body: body)
    }
    
    private func nextMultiPartLine(generator: inout IndexingGenerator<[UInt8]>) -> String? {
        var result = String()
        while let value = generator.next() {
            if value > Multiparser.CR {
                result.append(Character(UnicodeScalar(value)))
            }
            if value == Multiparser.NL {
                break
            }
        }
        return result
    }
    
    static let CR = UInt8(13)
    static let NL = UInt8(10)
    
    private func nextMultiPartBody(generator: inout IndexingGenerator<[UInt8]>, boundary: String) -> Data? {
        
        var body = [UInt8]()
        
        let boundaryArray = [UInt8](boundary.utf8)
        
        var matchOffset = 0;
        
        while let x = generator.next() {
            
            matchOffset = ( x == boundaryArray[matchOffset] ? matchOffset + 1 : 0 )
            
            body.append(x)
            
            if matchOffset == boundaryArray.count {
                
                body.removeRange(Range<Int>(body.count - matchOffset ..< body.count))
                
                if body.last == Multiparser.NL {
                    
                    body.removeLast()
                    
                    if body.last == Multiparser.CR {
                        body.removeLast()
                    }
                }
                
                return Data(bytes: body)
            }
        }
        return nil
    }
    
}
