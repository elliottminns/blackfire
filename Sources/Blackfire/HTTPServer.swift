
import Foundation

protocol HTTPServerDelegate {
    func server(_ server: HTTPServer, didReceive request: HTTPRequest, 
        response: HTTPResponse)
}

class HTTPServer {
    
    public var port: Int {
        return currentPort
    }
    
    var currentPort: Int
    
    var server: Server?
    
    public var delegate: HTTPServerDelegate?
    
    public init() {
        currentPort = 80
        self.delegate = nil
    }
    
    public init(delegate: HTTPServerDelegate) {
        currentPort = 80
        self.delegate = delegate
    }
    
    public func listen(port: Int) throws {
        self.currentPort = port
        if server == nil {
            server = try Server(port: port, delegate: self, type: .tcp)
            try server?.listen()
        }
    }
    
    func sendErrorResponse(toConnection connection: Connection) {
        let response = "HTTP/1.1 400 Client Error"
        connection.write(response)
    }
    
}

extension HTTPServer: ServerDelegate {
    
    public func server(_ server: Server, didCreateConnection connection: Connection) {
        
        var data = Data()
        
        connection.read { buffer, amount in
            
            data.append(buffer.buffer, length: amount)
            
            do {
                guard let request = try HTTPParser(data: data).parse() else { return }
                request.connection = connection
                
                let response = HTTPResponse(connection: connection)
                self.delegate?.server(self, didReceive: request,
                    response: response)
            } catch {
//                if let error = error as? ParserError {
//                    print(error.message)
//                    print(error.problemArea)
//                }
//                self.sendErrorResponse(toConnection: connection)
            }
        }
    }
}
