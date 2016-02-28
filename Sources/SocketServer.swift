import Echo
import Foundation
import Vaquita

#if os(Linux)
    import Glibc
#endif

protocol SocketServerDelegate: class {
    func socketServer(socketServer: SocketServer,
                      didRecieveRequest request: Request,
                                        withResponse response: Response)
}

public class SocketServer {

    let socketManager: SocketManager

    private var listenSocket: Socket = Socket(rawSocket: -1)
    
    private var clientSockets: Set<Socket> = []

    private var clientSocketsLock = NSLock()

    private var queue: dispatch_queue_t

    private let socketParser: SocketParser
    
    weak var delegate: SocketServerDelegate?

    init() {
        socketManager = SocketManager()
        queue = dispatch_queue_create("blackfish.queue.request", DISPATCH_QUEUE_CONCURRENT)
        socketParser = SocketParser()
    }

    func start(listenPort: Int) throws {

        self.stop()

        self.listenSocket = try socketManager.createListenSocket(listenPort)

        dispatch_async(self.queue) {

            while let socket = try? self.listenSocket.acceptClientSocket() {

                self.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }

                dispatch_async(self.queue) {
                    self.handleConnection(socket)
                    self.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                }
            }

            self.stop()
        }
    }

    func loop() {
        Echo.beginEventLoop()
    }

    func handleConnection(socket: Socket) {

        let address = try? socket.peername()

        if let request = try? socketParser.readHttpRequest(socket) {

            dispatch_async(dispatch_get_main_queue()) {

                request.address = address

                request.parameters = [:]
                
                let response = Response(request: request, responder: self, 
                    socket: socket)

                self.delegate?.socketServer(self,
                                           didRecieveRequest: request,
                                           withResponse: response)
            }
        }
    }

    func stop() {

        self.listenSocket.release()

        self.lock(self.clientSocketsLock) {
            for socket in self.clientSockets {
                socket.release()
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }

    private func lock(handle: NSLock, closure: () -> ()) {
        handle.lock()
        closure()
        handle.unlock();
    }
}

extension SocketServer: Responder {
    public func sendResponse(response: Response) {

        let socket = response.socket

        defer { socket
            response.request?.fireOnFinish()
            socket.release()
        }

        do {
            try socket.writeString("HTTP/1.1 \(response.status.code) \(response.reasonPhrase)\r\n")

            var headers = response.headers()

            if response.body.count >= 0 {
                headers["Content-Length"] = "\(response.body.count)"
            }

            if true && response.body.count != -1 {
                headers["Connection"] = "keep-alive"
            }

            for (name, value) in headers {
                try socket.writeString("\(name): \(value)\r\n")
            }

            try socket.writeString("\r\n")

            try socket.writeData(Data(bytes: response.body))

        } catch let socketError as SocketError {
            if let message = socketError.errorMessage {
                print("Error: \(socketError) error message: \(message)")
            } else {
                print("Error: \(socketError)")
            }
        } catch {
            print("Error: \(error)")
        }
    }
}
