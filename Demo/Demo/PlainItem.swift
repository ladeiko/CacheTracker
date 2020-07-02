//
//  PlainItem.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/13/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation
import CacheTracker

class PlainItem: NSObject, CacheTrackerPlainModel {
    
    @objc
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    // MARK: - CacheTrackerPlainModel
}

extension PlainItem: ArrayCacheTrackerElement {

    func evaluate(_ predicate: NSPredicate) -> Bool {
        return true
    }

    static func sort(_ descriptors: [NSSortDescriptor], lhs: PlainItem, rhs: PlainItem) -> Bool {
        return lhs.name < rhs.name
    }
}
