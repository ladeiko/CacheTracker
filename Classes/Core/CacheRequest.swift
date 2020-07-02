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
    
    public let predicate: NSPredicate
    public let sortDescriptors: [NSSortDescriptor]
    public let fetchLimit: Int
    
    public init(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor], fetchLimit: Int = 0) {
        assert(!sortDescriptors.isEmpty)
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }

    public init(sortDescriptors: [NSSortDescriptor], fetchLimit: Int = 0) {
        assert(!sortDescriptors.isEmpty)
        self.predicate = NSPredicate(value: true)
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }

    public init(predicate: NSPredicate, fetchLimit: Int = 0) {
        self.predicate = predicate
        self.sortDescriptors = []
        self.fetchLimit = fetchLimit
    }

    public init(fetchLimit: Int = 0) {
        self.predicate = NSPredicate(value: true)
        self.sortDescriptors = []
        self.fetchLimit = fetchLimit
    }
    
}
