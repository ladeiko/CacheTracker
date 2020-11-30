//
//  ArrayCacheRequestComparator.swift
//  CacheTracker
//
//  Created by Siarhei Ladzeika on 11/29/20.
//

import Foundation

public struct ArrayCacheRequestComparator<Target> {
    public let compare: (Target, Target) -> Bool
    public init(comparator: @escaping (Target, Target) -> Bool) {
        compare = comparator
    }
}
