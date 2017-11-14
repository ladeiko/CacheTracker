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
    
    public init(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) {
        assert(!sortDescriptors.isEmpty)
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }
    
}
