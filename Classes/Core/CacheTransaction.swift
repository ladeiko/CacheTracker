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
    
    public let model: P?
    public let index: Int?
    public let newIndex: Int?
    public let type: CacheTransactionType
    
    public init(model: P?, index: Int?, newIndex: Int?, type: CacheTransactionType) {
        self.model = model
        self.index = index
        self.newIndex = newIndex
        self.type = type
    }
    
}

