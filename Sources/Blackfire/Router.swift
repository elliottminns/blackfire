import Foundation

public class Router {
  public let pathHandler: PathHandler = PathHandler()
  
  public init() {}
}

extension Router: PathRouting {
  
}
