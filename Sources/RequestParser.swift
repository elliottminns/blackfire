
#if os(Linux)
    import Glibc
#endif

import Foundation
import Echo

enum RequestParserError: ErrorType {
    case InvalidStatusLine(String)
}

extension Data {
    var lines: [String] {
        
        var lines: [String] = []
        
        var line = ""
        
        for byte in bytes {
            if byte > 13 {
                line.append(Character(UnicodeScalar(byte)))
            } else {
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

        let statusLineTokens = statusLine.splitWithCharacter(" ")

        if statusLineTokens.count < 3 {
            throw RequestParserError.InvalidStatusLine(statusLine)
        }

        let method = Request.Method(rawValue: statusLineTokens[0]) ?? .Unknown
        let request = Request(method: method)

        request.path = statusLineTokens[1]
        request.data = extractQueryParams(request.path)
        request.headers = try readHeaders(lines)

        if let cookieString = request.headers["cookie"] {
            let cookies = cookieString.splitWithCharacter(";")
            for cookie in cookies {
                let cookieArray = cookie.splitWithCharacter("=")
                if cookieArray.count == 2 {
                    let key = cookieArray[0].stringByReplacingOccurrencesOfString(" ", withString: "")
                    request.cookies[key] = cookieArray[1]
                }
            }
        }

        if let contentLength = request.headers["content-length"],

            let _ = Int(contentLength) {

                let bodyString = try data.toString()
                let postArray = bodyString.splitWithCharacter("&")
                for postItem in postArray {
                    let pair = postItem.splitWithCharacter("=")
                    if pair.count == 2 {
                        request.data[pair[0]] = pair[1]
                    }
                }

                request.body = data
        }

        return request
    }

    private func extractQueryParams(url: String) -> [String: Any] {
        var query = [String: Any]()

        var urlParts = url.splitWithCharacter("?")
        if urlParts.count < 2 {
            return query
        }

        for subQuery in urlParts[1].splitWithCharacter("&") {
            let tokens = subQuery.splitWithCharacter("=")
            if let name = tokens.first?.stringByRemovingPercentEncoding,
                value = tokens.last?.stringByRemovingPercentEncoding {
                    query[name] = value
            }
        }

        return query
    }

    private func readHeaders(lines: [String]) throws -> [String: String] {
        
        var requestHeaders = [String: String]()
        
        for line in lines.filter({ $0.isEmpty == false }) {
            
            let headerTokens = line.splitWithCharacter(":")
            
            if let name = headerTokens.first, value = headerTokens.last {
                requestHeaders[name.lowercaseString] = value.trimWhitespace()
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
