//
//  Random.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 5/8/18.
//  Copyright © 2018 Siarhei Ladzeika. All rights reserved.
//

import Foundation

extension Int {
    static func random() -> Int {
        return Int(arc4random())
    }
}

extension UInt {
    static func random() -> UInt {
        return UInt(arc4random())
    }
}
