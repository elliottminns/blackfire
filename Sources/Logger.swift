import Foundation

final public class Logger {
	enum ANSIColors: String {
    	case black = "\u{001B}[0;30m"
    	case red = "\u{001B}[0;31m"
    	case green = "\u{001B}[0;32m"
    	case yellow = "\u{001B}[0;33m"
    	case blue = "\u{001B}[0;34m"
    	case magenta = "\u{001B}[0;35m"
    	case cyan = "\u{001B}[0;36m"
    	case white = "\u{001B}[0;37m"

    	func name() -> String {
        	switch self {
        	case black: return "Black"
        	case red: return "Red"
        	case green: return "Green"
        	case yellow: return "Yellow"
        	case blue: return "Blue"
        	case magenta: return "Magenta"
        	case cyan: return "Cyan"
        	case white: return "White"
            }
        }
        static func all() -> [ANSIColors] {
            return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white]
	    }
    }
    
    public init() {
        
    }
}

func + (let left: Logger.ANSIColors, let right: String) -> String {
   	return left.rawValue + right
}

extension Logger: Middleware {
    
    public func handle(request: Request, response: Response, next: () -> ()) {
 		defer { next() }
        
        let method = ANSIColors.green + request.method.rawValue
        
        let path = ANSIColors.black + request.path
		
        request.data["startTime"] = NSDate.timeIntervalSinceReferenceDate()
        
        request.addListener(event: Event.OnFinish) {
            
            let finishTime = NSDate.timeIntervalSinceReferenceDate()
            
            var log = "\(method) \(path)"
            
            if let startTime = request.data["startTime"] as? NSTimeInterval {
                let delta = (finishTime - startTime) * 1000
                log += String(format: " - \(Int(delta)) ms")
            }
            
            print(log)
        }
    }
}
