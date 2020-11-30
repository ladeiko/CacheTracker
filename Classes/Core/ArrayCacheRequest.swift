//
//  ArrayCacheRequest.swift
//  CacheTracker
//
//  Created by Siarhei Ladzeika on 11/29/20.
//

import Foundation

internal class ArrayCacheRequest<T>: CacheRequest {

    let filter: ArrayCacheRequestFilter<T>?
    let comparator: ArrayCacheRequestComparator<T>?
    let range: Range<Int>?

    init(filter: ArrayCacheRequestFilter<T>?, comparator: ArrayCacheRequestComparator<T>?, range: Range<Int>?) {
        self.filter = filter
        self.comparator = comparator
        self.range = range
    }
}
