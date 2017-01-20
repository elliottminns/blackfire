
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
  
  var queueType: QueueType
  
  init(socket: Socket, queueType: QueueType) {
    self.socket = socket
    self.writeData = Data()
    self.queueType = queueType
  }
  
  public func read(callback: @escaping (_ data: Buffer, _ amount: Int) -> ()) {
    let fd = Int32(socket.raw)
    readSource = DispatchSource.makeReadSource(fileDescriptor: fd,
                                               queue: queueType.dispatchQueue())
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
    let writeSource = DispatchSource.makeWriteSource(fileDescriptor: socket.raw,
                                                     queue: queueType.dispatchQueue())
    
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
