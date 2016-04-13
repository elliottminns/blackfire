import Foundation

protocol SessionDriver {
	var sessions: [String: Session] { get set }
}

public class Session {

	public enum DriverType {
		case File, Memory
	}
    
	public static var type: DriverType = .Memory {
		didSet {
			switch self.type {
				case .Memory:
					self.driver = MemorySessionDriver()
				case .File:
					fatalError("File driver not yet supported")
			}
		}
	}
	static var driver: SessionDriver = MemorySessionDriver()

	public static func start(_ request: Request) {
		if let key = request.cookies["blackfish-session"] {
			if let session = self.driver.sessions[key] {
				request.session = session
			} else {
				request.session.key = key
				self.driver.sessions[key] = request.session
			}
		}
	}

	public static func close(request: Request, response: Response) {
		if let key = request.session.key {
			response.cookies["blackfish-session"] = key
		} 
	}

	init() {
		//do nothing
	}

	public func destroy() {
        Session.driver.sessions.removeAll();
	}

	var key: String?
	public var data: [String: String] = [:] {
		didSet {
			if self.key == nil {
#if os(Linux)
				let key = NSUUID().UUIDString
#else
				let key = NSUUID().uuidString
#endif
				self.key = key
				Session.driver.sessions[key] = self
			}
		}
	}

}
