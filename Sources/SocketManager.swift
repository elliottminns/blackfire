#if os(Linux)
import Glibc
#else
import Darwin
#endif


class SocketManager {

    func createListenSocket(port: Int,
        pendingConnectionCount: Int32 = SOMAXCONN) throws -> Socket {

        let port = UInt16(port)

        #if os(Linux)
            let socketStream = Int32(SOCK_STREAM.rawValue)
        #else
            let socketStream = SOCK_STREAM
        #endif

        let rawSocket = socket(AF_INET, socketStream, 0)

        if rawSocket == -1 {
            throw SocketError.SocketCreationFailed(Socket.descriptionOfLastError())
        }

        var value: Int32 = 1

        if setsockopt(rawSocket, SOL_SOCKET, SO_REUSEADDR,
            &value, socklen_t(sizeof(Int32))) == -1 {
                let details = Socket.descriptionOfLastError()
                SocketManager.closeRawSocket(rawSocket)
                throw SocketError.SocketSettingReUseAddrFailed(details)
        }

        Socket.setNoSigPipe(rawSocket)

        var socketAddress = sockaddr_in()
        socketAddress.sin_family = sa_family_t(AF_INET)
        socketAddress.sin_port = Socket.htonsPort(port)
        #if os(Linux)
            socketAddress.sin_addr = in_addr(s_addr: in_addr_t(0))
        #else
            socketAddress.sin_len = __uint8_t(sizeof(sockaddr_in))
            socketAddress.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
        #endif

        socketAddress.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)

        var bindAddress = sockaddr()

        memcpy(&bindAddress, &socketAddress, Int(sizeof(sockaddr_in)))

        if bind(rawSocket, &bindAddress, socklen_t(sizeof(sockaddr_in))) == -1 {
            let details = Socket.descriptionOfLastError()
            SocketManager.closeRawSocket(rawSocket)
            throw SocketError.BindFailed(details)
        }

        if listen(rawSocket, pendingConnectionCount ) == -1 {
            let details = Socket.descriptionOfLastError()
            SocketManager.closeRawSocket(rawSocket)
            throw SocketError.ListenFailed(details)
        }

        return Socket(rawSocket: rawSocket)

    }

    class func closeSocket(socket: Socket) {
        closeRawSocket(socket.rawSocket)
    }

    class func shutdownSocket(socket: Socket) {
        shutdownRawSocket(socket.rawSocket)
    }

    class func closeRawSocket(socket: Int32) {
        SocketManager.shutdownRawSocket(socket)
        close(socket)
    }

    class func shutdownRawSocket(socket: Int32) {
        #if os(Linux)
            shutdown(socket, Int32(SHUT_RDWR))
        #else
            Darwin.shutdown(socket, SHUT_RDWR)
        #endif
    }

}
