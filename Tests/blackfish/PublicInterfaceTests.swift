//
//  PublicInterfaceTests.swift
//  Blackfish
//
//  Created by Elliott Minns on 06/02/2016.
//  Copyright © 2016 Elliott Minns. All rights reserved.
//

import XCTest

import Blackfish

class PublicInterfaceTests: XCTestCase {

    var server: Blackfish!
    
    override func setUp() {
        super.setUp()
        
        server = Blackfish()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetInterface() {
        server.get("") { (request, response) -> Void in
            
        }
    }
    
    func testPutInterface() {
        server.put("") { (request, response) -> Void in
            
        }
    }
    
    func testPostInterface() {
        server.post("") { (request, response) -> Void in
            
        }
    }

}
