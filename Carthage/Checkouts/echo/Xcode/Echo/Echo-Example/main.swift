//
//  main.swift
//  Echo-Example
//
//  Created by Elliott Minns on 12/02/2016.
//  Copyright © 2016 Elliott Minns. All rights reserved.
//

import Echo

let serial = dispatch_queue_create("com.serial", DISPATCH_QUEUE_SERIAL)

dispatch_async(dispatch_get_global_queue(0, 0)) {
    var array = [Int]()
    for i in 0 ..< 1000 {
        dispatch_async(dispatch_get_main_queue()) {
            dispatch_async(serial, { 
                print(i)
            })
            
        }
    }
}

Echo.beginEventLoop()