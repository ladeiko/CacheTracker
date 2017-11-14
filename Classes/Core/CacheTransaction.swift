//
//  CacheTransaction.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

import Foundation

public enum CacheTransactionType : UInt {
    case insert
    case delete
    case move
    case update
}

open class CacheTransaction<P: CacheTrackerPlainModel> {
    
    open let model: P?
    open let index: Int?
    open let newIndex: Int?
    open let type: CacheTransactionType
    
    init(model: P?, index: Int?, newIndex: Int?, type: CacheTransactionType) {
        self.model = model
        self.index = index
        self.newIndex = newIndex
        self.type = type
    }
    
}
