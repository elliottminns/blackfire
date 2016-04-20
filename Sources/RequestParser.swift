
#if os(Linux)
    import Glibc
#endif

import Foundation
import Echo

enum RequestParserError: ErrorProtocol {
    case InvalidStatusLine(String)
    case NotRecievedAllContent
}

extension Data {
    var lines: [String] {
        
        var lines: [String] = []
        
        var line = ""
        
        for byte in bytes {
            if byte > 13 {
                line.append(Character(UnicodeScalar(byte)))
            } else if !line.isEmpty {
                lines.append(line)
                line = ""
            }
        }
        
        lines.append(line)
        
        return lines
    }
}

class RequestParser {

    func readHttpRequest(data: Data) throws -> Request {
        
        var lines = data.lines
        
        guard let statusLine = lines.first else {
            throw RequestParserError.InvalidStatusLine("")
        }
        
        lines.removeFirst()

        let statusLineTokens = statusLine.split(withCharacter: " ")

        if statusLineTokens.count < 3 {
            throw RequestParserError.InvalidStatusLine(statusLine)
        }

        let method = Request.Method(rawValue: statusLineTokens[0]) ?? .Unknown
        let request = Request(method: method)

        request.path = statusLineTokens[1]
        
        if method == .Get {
            
            let params = extractQueryParams(url: request.path)
            
            for (key, value) in params {
                
                request.data[key] = value
            }
        }
        
        request.headers = try readHeaders(lines: &lines)

        if let cookieString = request.headers["cookie"] {
            let cookies = cookieString.split(withCharacter: ";")
            for cookie in cookies {
                let cookieArray = cookie.split(withCharacter: "=")
                if cookieArray.count == 2 {

#if os(Linux)
                    let key = cookieArray[0]
                        .stringByReplacingOccurrencesOfString(" ", 
                                withString: "")
#else
                    let key = cookieArray[0].replacingOccurrences(of: " ", 
                                                                  with: "")
#endif
                    request.cookies[key] = cookieArray[1]
                }
            }
        }

        if let contentLength = request.headers["content-length"],
            
            let contentSize = Int(contentLength) {
            
            if let bodyString = lines.last where bodyString.characters.count == contentSize {
                
                let postArray = bodyString.split(withCharacter: "&")
                for postItem in postArray {
                    let pair = postItem.split(withCharacter: "=")
                    if pair.count == 2 {
                        let key             = pair[0]
                        let encodedValue    = pair[1]
                        if let value = encodedValue.removingPercentEncoding {
                            request.data[key]   = value
                        }
                    }
                }
                
                let body = Data(string: bodyString)
                request.body = body
            } else {
                throw RequestParserError.NotRecievedAllContent
            }
        }

        return request
    }

    private func extractQueryParams(url: String) -> [String: Any] {
        var query = [String: Any]()

        var urlParts = url.split(withCharacter: "?")
        if urlParts.count < 2 {
            return query
        }

        for subQuery in urlParts[1].split(withCharacter: "&") {
            let tokens = subQuery.split(withCharacter: "=")
            if let name = tokens.first?.removingPercentEncoding,
                value = tokens.last?.removingPercentEncoding {
                    query[name] = value
            }
        }

        return query
    }

    private func readHeaders(lines: inout [String]) throws -> [String: String] {
        
        var requestHeaders = [String: String]()
        
        for line in lines.filter({ $0.isEmpty == false }) {
            
            let headerTokens = line.split(withCharacter: ":")
            
            if let name = headerTokens.first, value = headerTokens.last {
                requestHeaders[name.lowercased()] = value.trimWhitespace()
            }
        }
        
        return requestHeaders
    }

    func supportsKeepAlive(headers: [String: String]) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.trimWhitespace()
        }
        return false
    }
}
