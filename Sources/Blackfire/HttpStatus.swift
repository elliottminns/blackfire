import Foundation

enum HTTPStatus {
    case `continue`
    case ok
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case movedPermanently
    case found
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case unknown(Int)
}

fileprivate let map: [Int: HTTPStatus] = [
    100: .continue,
    
    200: .ok, 201: .created, 202: .accepted, 203: .nonAuthoritativeInformation,
    204: .noContent, 205: .resetContent, 206: .partialContent,
    
    301: .movedPermanently, 302: .found,
    
    400: .badRequest, 401: .unauthorized, 402: .paymentRequired,
    403: .forbidden, 404: .notFound,
    
    500: .internalServerError, 501: .notImplemented, 502: .badGateway,
    503: .serviceUnavailable, 504: .gatewayTimeout
]

extension HTTPStatus {
    
    init(status: Int) {
        self = map[status] ?? .unknown(status)
    }
    
    var stringValue: String {
        let value: String
        
        switch self {
        case .ok: value = "200 OK"
        case .`continue`: value =  "100 Continue"
        case .created: value =  "201 Created"
        case .accepted: value =  "202 Accepted"
        case .nonAuthoritativeInformation: value = "203 Non Authoritative Information"
        case .noContent: value = "204 No Content"
        case .resetContent: value = "205 Reset Content"
        case .partialContent: value = "206 Partial Content"
        case .movedPermanently: value = "301 Moved Permanently"
        case .found: value = "302 Found"
        case .badRequest: value = "400 Bad Request"
        case .unauthorized: value = "401 Unauthorized"
        case .paymentRequired: value = "402 Payment Required"
        case .forbidden: value = "403 Forbidden"
        case .notFound: value = "404 Not Found"
        case .internalServerError: value = "500 Internal Server Error"
        case .notImplemented: value = "501 Not Implemented"
        case .badGateway: value = "502 Bad Gateway"
        case .serviceUnavailable: value = "503 Service Unavailable"
        case .gatewayTimeout: value = "504 Gateway Timeout"
        case .unknown(let status): value = "\(status)"
        }
        
        return value
    }
}
