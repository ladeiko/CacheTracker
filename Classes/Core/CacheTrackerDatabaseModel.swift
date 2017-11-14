//
//  CacheTrackerDatabaseModel.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

import Foundation

public protocol CacheTrackerDatabaseModel: class, NSObjectProtocol {
    
    static func entityName() -> String
    func toPlainModel<P>() -> P?
}
