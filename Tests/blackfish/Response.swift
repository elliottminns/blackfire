@testable import Blackfish
import XCTest

class MockResponder: Responder {
    
    var response: Response?
    
    func sendResponse(response: Response) {
        self.response = response
    }
    
}

class ResponseTests: XCTestCase {
    
    var response: Response!
    var request: Request!
    var socket: Socket!
    var responder: MockResponder!
    
    override func setUp() {
        super.setUp()
        
        request = Request(method: .Get)
        socket = Socket(rawSocket: 0)
        responder = MockResponder()
        
        response = Response(request: request, responder: responder, socket: socket)
    }
    
    func testSendCallsResponder() {
        response.send()
        XCTAssertNotNil(responder.response)
    }
    
}