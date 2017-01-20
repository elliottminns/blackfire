
import Foundation

enum EncodingError: Error {
	case Failed
}

public struct Data {

	public var bytes: [UInt8]

	public var size: Int {
		return bytes.count
	}

	public var raw: UnsafeMutablePointer<UInt8> {
		return UnsafeMutablePointer<UInt8>(mutating: bytes)
	}

	public init() {
		self.bytes = []
	}

	public init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    public init(string: String) {
        self.bytes = [UInt8](string.utf8)
    }
    
    public init(base: UnsafeMutablePointer<Int8>, length: Int) {
        var bytes: [UInt8] = []
        base.withMemoryRebound(to: UInt8.self, capacity: 1) {
            bytes = Array(UnsafeBufferPointer(start: $0, count: length))
        }
        self.bytes = bytes
    }

    public func toString() throws -> String {
        var bytes = self.bytes
        guard let str = String(bytesNoCopy: &bytes,
            length: bytes.count * MemoryLayout<UInt8>.size,
            encoding: String.Encoding.utf8,
            freeWhenDone: false) else {
                throw EncodingError.Failed
        }

        return str
    }
    
    public mutating func append(_ bytes: [UInt8]) {
        self.bytes += bytes
    }
    
    public mutating func append(_ buffer: UnsafeRawPointer, length: Int) {
        guard length > 0 else { return }
        let bytes = buffer.bindMemory(to: UInt8.self, capacity: 1)
        let buf = UnsafeBufferPointer(start: bytes, count: length)
        self.bytes.append(contentsOf: buf)
    }
}
