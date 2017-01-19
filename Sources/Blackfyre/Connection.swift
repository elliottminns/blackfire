
import Foundation

#if os(Linux)
import Dispatch
#endif

public protocol Connection {
    func read(callback: @escaping (_ data: Buffer, _ amount: Int) -> ())
    func write(data: Data)
}

extension Connection {
    func write(_ string: String) {
        let writeData = Data(string: string)
        write(data: writeData)
    }
}

public class SocketConnection: Connection {
    
    let socket: Socket
    
    var writeData: Data
    
    var readSource: DispatchSourceRead?
    
    init(socket: Socket) {
        self.socket = socket
        self.writeData = Data()
    }
    
    public func read(callback: @escaping (_ data: Buffer, _ amount: Int) -> ()) {
        let fd = Int32(socket.raw)
        readSource = DispatchSource.makeReadSource(fileDescriptor: fd,
                                                   queue: DispatchQueue.main)
        let buffer = Buffer(size: 256)
        
        readSource?.setEventHandler {
            
            let amount = systemRead(self.socket.raw, buffer.buffer, buffer.size)
            
            if amount < 0 {
                self.readSource?.cancel()
            } else if amount == 0 {
                callback(buffer, amount)
                self.readSource?.cancel()
            } else {
                callback(buffer, amount)
            }
        }
        
        #if os(Linux)
            readSource?.resume()
        #else
            readSource?.resume()
        #endif
        
    }

    public func write(data: Data) {
        self.writeData = data
        let writeSource = DispatchSource.makeWriteSource(fileDescriptor: socket.raw, queue: DispatchQueue.main)

        var amount = 0
        writeSource.setEventHandler {

            amount += systemWrite(self.socket.raw,
                                  data.raw.advanced(by: amount),
                                  data.size - amount)

            if amount < 0 {
                writeSource.cancel()
            } else if amount == data.size {
                writeSource.cancel()
            }
            
        }

        #if os(Linux)
//        dispatch_resume(dispatch_object_t(_ds: writeSource))
            writeSource.resume()
        #else
            writeSource.resume()
        #endif
        
        writeSource.setCancelHandler {
            self.readSource?.cancel()
            self.socket.shutdown()
        }
    }
}
