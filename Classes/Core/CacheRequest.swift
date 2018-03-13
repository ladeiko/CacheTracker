//
//  CacheRequest.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

import Foundation

open class CacheRequest {
    
    open let predicate: NSPredicate
    open let sortDescriptors: [NSSortDescriptor]
    open let fetchLimit: Int
    
    public init(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], fetchLimit: Int = 0) {
        assert(!sortDescriptors.isEmpty)
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }
    
}
