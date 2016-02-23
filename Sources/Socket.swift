#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

import Vaquita

enum SocketType {
    case TCP
    case UDP
}

enum SocketError: ErrorType {
    case SocketCreationFailed(String)
    case SocketSettingReUseAddrFailed(String)
    case BindFailed(String)
    case ListenFailed(String)
    case WriteFailed(String)
    case GetPeerNameFailed(String)
    case ConvertingPeerNameFailed
    case GetNameInfoFailed(String)
    case AcceptFailed(String)
    case RecvFailed(String)

    var errorMessage: String? {
        switch self {
        case let .SocketCreationFailed(message):
            return message
        case let .SocketSettingReUseAddrFailed(message):
            return message
        case let .BindFailed(message):
            return message
        case let .ListenFailed(message):
            return message
        case let .WriteFailed(message):
            return message
        case let .GetPeerNameFailed(message):
            return message
        case let .GetNameInfoFailed(message):
            return message
        case let .AcceptFailed(message):
            return message
        case let .RecvFailed(message):
            return message
        default:
            return nil
        }
    }
}

struct Socket {

    let rawSocket: Int32

    var peerName: String?

    init(rawSocket: Int32) {
        self.rawSocket = rawSocket
    }

    func release() {
        SocketManager.closeRawSocket(rawSocket)
    }

    func shutdown() {
        SocketManager.shutdownRawSocket(rawSocket)
    }

    func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()
        var len: socklen_t = 0
        let clientSocket = accept(rawSocket, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.AcceptFailed(Socket.descriptionOfLastError())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(rawSocket: clientSocket)
    }

    func writeString(string: String) throws {
        let data = Data(string: string)
        try writeData(data)
    }

    func writeData(data: Data) throws {
        try data.bytes.withUnsafeBufferPointer {

            var sent = 0

            while sent < data.bytes.count {

                #if os(Linux)
                    let s = send(self.rawSocket,
                        $0.baseAddress + sent, Int(data.size - sent),
                        Int32(MSG_NOSIGNAL))
                #else
                    let s = write(self.rawSocket,
                        $0.baseAddress + sent, Int(data.size - sent))
                #endif

                if s <= 0 {
                    throw SocketError.WriteFailed(Socket.descriptionOfLastError())
                }
                sent += s
            }
        }
    }

    func read() throws -> UInt8 {
        var buffer = [UInt8](count: 1, repeatedValue: 0)
        let next = recv(self.rawSocket as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            throw SocketError.RecvFailed(Socket.descriptionOfLastError())
        }
        return buffer[0]
    }

    private static let CR = UInt8(13)

    private static let NL = UInt8(10)

    func readLine() throws -> String {
        var characters: String = ""
        var n: UInt8 = 0
        repeat {
            n = try self.read()
            if n > Socket.CR { characters.append(Character(UnicodeScalar(n))) }
        } while n != Socket.NL
        return characters
    }

    func peername() throws -> String {

        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))

        if getpeername(self.rawSocket, &addr, &len) != 0 {
            throw SocketError.GetPeerNameFailed(Socket.descriptionOfLastError())
        }

        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)

        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.GetNameInfoFailed(Socket.descriptionOfLastError())
        }

        guard let name = String.fromCString(hostBuffer) else {
            throw SocketError.ConvertingPeerNameFailed
        }

        return name
    }

    static func descriptionOfLastError() -> String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }

    static func setNoSigPipe(socket: Int32) {
        #if os(Linux)
            // There is no SO_NOSIGPIPE in Linux (nor some other systems). You can instead use the MSG_NOSIGNAL flag when calling send(),
            // or use signal(SIGPIPE, SIG_IGN) to make your entire application ignore SIGPIPE.
        #else
            // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
            var no_sig_pipe: Int32 = 1
            setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)))
        #endif
    }

    static func htonsPort(port: in_port_t) -> in_port_t {
        #if os(Linux)
            return port.bigEndian //use htons(). LLVM Crash currently
        #else
            let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return isLittleEndian ? _OSSwapInt16(port) : port
        #endif
    }
}

extension Socket: Hashable {

    var hashValue: Int {

        return Int(self.rawSocket)
    }
}

extension Socket: Equatable {
}

func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.rawSocket == socket2.rawSocket
}
