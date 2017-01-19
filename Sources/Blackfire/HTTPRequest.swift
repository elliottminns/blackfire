
import Foundation

public class HTTPRequest {
    
    public let method: HTTPMethod
    
    public let headers: [String: String]
    
    public let body: String
    
    public let query: [String: Any]
    
    public let path: String
    
    public let httpProtocol: String
    
    var connection: Connection?
    
    public init(headers: [String: String],
                method: HTTPMethod,
                body: String,
                path: String,
                httpProtocol: String) {
        
        self.headers = headers
        self.body = body
        self.method = method
        self.httpProtocol = httpProtocol
        let pathComps = path.components(separatedBy: "?")
        self.path = pathComps.first ?? "/"
        var query: [String: Any] = [:]
        
        if pathComps.count > 1 {
            pathComps.last?.components(separatedBy: "&")
                .flatMap { (keypair) -> (key: String, value: String)? in
                    let comps = keypair.components(separatedBy: "=")
                    guard let first = comps.first, let last = comps.last else {
                        return nil
                    }
                    return (key: first, value: last)
                }.forEach {
                    if (query[$0.key] is Array<Any>) {
                        query[$0.key] = (query[$0.key] as! Array<Any>) + [$0.value]
                    } else if (query[$0.key] is String) {
                        guard let value = query[$0.key] else {
                            query[$0.key] = $0.value
                            return
                        }
                        query[$0.key] = [value, $0.value]
                    } else {
                        query[$0.key] = $0.value
                    }
                    
            }
        }
        
        self.query = query
    }
}
