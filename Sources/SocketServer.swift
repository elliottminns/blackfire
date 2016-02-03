//
// Based on HttpServerIO from Swifter (https://github.com/glock45/swifter) by Damian Kołakowski.
//

import Foundation

#if os(Linux)
    import Glibc
#endif

public class SocketServer {

    /// A socket open to the port the server is listening on. Usually 80.
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)

    /// A set of connected client sockets.
    private var clientSockets: Set<Socket> = []

    /// The shared lock for notifying new connections.
    private let clientSocketsLock = NSLock()
    
    /// The queue to dispatch requests on.
    private var queue: dispatch_queue_t
    
    init() {
        queue = dispatch_queue_create("blackfish.queue.request", DISPATCH_QUEUE_CONCURRENT)
    }

    /**
        Starts the server on a given port.
        - parameter listenPort: The port to listen on.
    */
    func start(listenPort: Int) throws {
        // Stop the server if it's running
        self.stop()

        // Open a socket, might fail
        self.listenSocket = try Socket.tcpSocketForListen(UInt16(listenPort))

        dispatch_async(self.queue) {

            //creates the infinite loop that will wait for client connections
            while let socket = try? self.listenSocket.acceptClientSocket() {

                //wait for lock to notify a new connection
                self.lock(self.clientSocketsLock) {
                    //keep track of open sockets
                    self.clientSockets.insert(socket)
                }

                dispatch_async(self.queue) {
                    self.handleConnection(socket)
                }
                    
                dispatch_async(self.queue) {
                    self.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                }
            }

            //stop the server in case something didn't work
            self.stop()
        }
    }

    /**
        Starts an infinite loop to keep the server alive while it
        waits for inbound connections.
    */
    func loop() {
        #if os(Linux)
            while true {
                sleep(1)
            }
        #else
            NSRunLoop.mainRunLoop().run()
        #endif
    }

    func handleConnection(socket: Socket) {
        //try to get the ip address of the incoming request (like 127.0.0.1)
        let address = try? socket.peername()

        //create a request parser
        let parser = Parser()

        if let request = try? parser.readHttpRequest(socket) {
            
            dispatch_async(dispatch_get_main_queue()) {
                
                //dispatch the server to handle the request
                let handler = self.dispatch(request.method, path: request.path)
                
                //add parameters to request
                request.address = address
                request.parameters = [:]
                
                let response = Response(request: request, responder: self, socket: socket)
                handler(request, response)
            }
        }
    }

    /**
        Returns a closure that given a Request returns a Response

        - returns: DispatchResponse
    */
    func dispatch(method: Request.Method, path: String) -> ((Request, Response) -> Void) {
        return { request, response in
            
            response.status = .NotFound
            response.send(text: "Page not found")
            
        }
    }

    /**
        Stops the server
    */
    func stop() {
        //free the port
        self.listenSocket.release()

        //shutdown all client sockets
        self.lock(self.clientSocketsLock) {
            for socket in self.clientSockets {
                socket.shutdwn()
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }

    /**
        Locking mechanism for holding thread until a
        new socket connection is ready.

        - parameter handle: NSLock
        - parameter closure: Code that will run when the lock has been altered.
    */
    private func lock(handle: NSLock, closure: () -> ()) {
        handle.lock()
        closure()
        handle.unlock();
    }
}

extension SocketServer: Responder {
    public func sendResponse(response: Response) {
        
        let socket = response.socket
        
        defer { [socket]
            Session.close(request: response.request, response: response)
            socket.release()
        }
        
        do {
            try socket.writeUTF8("HTTP/1.1 \(response.status.code) \(response.reasonPhrase)\r\n")
            
            var headers = response.headers()
            
            if response.body.count >= 0 {
                headers["Content-Length"] = "\(response.body.count)"
            }
            
            if true && response.body.count != -1 {
                headers["Connection"] = "keep-alive"
            }
            
            for (name, value) in headers {
                try socket.writeUTF8("\(name): \(value)\r\n")
            }
            
            try socket.writeUTF8("\r\n")
            
            try socket.writeUInt8(response.body)
            
        } catch {
            print(error)
        }
    }
}
