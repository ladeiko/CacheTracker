//
//  ArrayCacheRequestPredicate.swift
//  CacheTracker
//
//  Created by Siarhei Ladzeika on 11/29/20.
//

import Foundation

public struct ArrayCacheRequestFilter<Target> {
    public let matches: (Target) -> Bool
    public init(matcher: @escaping (Target) -> Bool) {
        matches = matcher
    }
}
