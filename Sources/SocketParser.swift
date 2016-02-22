//
// Based on HttpParser from Swifter (https://github.com/glock45/swifter) by Damian Kołakowski.
//

#if os(Linux)
    import Glibc
#endif

import Foundation
import Vaquita

enum SocketParserError: ErrorType {
    case InvalidStatusLine(String)
}

class SocketParser {
    
    func readHttpRequest(socket: Socket) throws -> Request {
        
        let statusLine = try socket.readLine()
        
        let statusLineTokens = statusLine.split(" ")
        
        if statusLineTokens.count < 3 {
            throw SocketParserError.InvalidStatusLine(statusLine)
        }

        let method = Request.Method(rawValue: statusLineTokens[0]) ?? .Unknown
        let request = Request(method: method)
        
        request.path = statusLineTokens[1]
        request.data = extractQueryParams(request.path)
        request.headers = try readHeaders(socket)

        if let cookieString = request.headers["cookie"] {
            let cookies = cookieString.split(";")
            for cookie in cookies {
                let cookieArray = cookie.split("=")
                if cookieArray.count == 2 {
                    let key = cookieArray[0].stringByReplacingOccurrencesOfString(" ", withString: "")
                    request.cookies[key] = cookieArray[1]
                }
            }
        }

        if let contentLength = request.headers["content-length"],
            
            let contentLengthValue = Int(contentLength) {
                
                let body = try readBody(socket, size: contentLengthValue)
                
                let bodyString = try body.toString()
                let postArray = bodyString.split("&")
                for postItem in postArray {
                    let pair = postItem.split("=")
                    if pair.count == 2 {
                        request.data[pair[0]] = pair[1]
                    }
                }
                
                request.body = body
        }

        return request
    }
    
    private func extractQueryParams(url: String) -> [String: Any] {
        var query = [String: Any]()

        var urlParts = url.split("?")
        if urlParts.count < 2 {
            return query
        }

        for subQuery in urlParts[1].split("&") {
            let tokens = subQuery.split(1, separator: "=")
            if let name = tokens.first, value = tokens.last {
                query[name.removePercentEncoding()] = value.removePercentEncoding()
            }
        }

        return query
    }
    
    private func readBody(socket: Socket, size: Int) throws -> Data {
        var body = [UInt8]()
        var counter = 0
        while counter < size {
            body.append(try socket.read())
            counter += 1
        }
        return Data(bytes: body)
    }
    
    private func readHeaders(socket: Socket) throws -> [String: String] {
        var requestHeaders = [String: String]()
        repeat {
            let headerLine = try socket.readLine()
            if headerLine.isEmpty {
                return requestHeaders
            }
            let headerTokens = headerLine.split(1, separator: ":")
            if let name = headerTokens.first, value = headerTokens.last {
                requestHeaders[name.lowercaseString] = value.trim()
            }
        } while true
    }
    
    func supportsKeepAlive(headers: [String: String]) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.trim()
        }
        return false
    }
}
