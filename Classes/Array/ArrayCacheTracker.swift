//
//  CoreDataCacheTracker.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation

open class ArrayCacheTracker<P: CacheTrackerPlainModel>: CacheTracker {

    open var fetchLimitThreshold: Int = 0

    fileprivate var _cacheRequest: ArrayCacheRequest<P>!
    fileprivate var _transactions: [CacheTransaction<P>]!
    fileprivate var _initialData: [P]
    fileprivate var _data: [P]!
    
    public init(data: [P]) {
        self._initialData = data.map({ $0 })
    }
    
    // MARK: - CacheTracker
    
    open weak var delegate: CacheTrackerDelegate?
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest, cacheName: String?) -> Void {

        guard let cacheRequest = cacheRequest as? ArrayCacheRequest<P> else {
            fatalError()
        }

        _cacheRequest = cacheRequest
        _data = _initialData

        if let matches = _cacheRequest.filter?.matches {
            _data = _data.filter(matches)
        }

        if let compare = _cacheRequest.comparator?.compare {
            _data = _data.sorted(by: compare)
        }

        if let range = _cacheRequest.range {
            _data = Array(_data[range])
        }

        delegate?.cacheTrackerShouldMakeInitialReload()
    }
    
    open func stopFetching() {
        // TODO
    }
    
    open func deleteCache(withName name: String?) {
        
    }
    
    open func object(at index: Int) -> P? {
        return _data[index]
    }
    
    open func numberOfObjects() -> Int {
        return _data.count
    }
    
    open func object(at indexPath: IndexPath) -> P? {
        return _data[indexPath.row]
    }
    
    open func allObjects() -> [P] {
        return _data.map({ $0 })
    }
    
    open func transactionsForCurrentState() -> [CacheTransaction<P>] {
        var transactions = [CacheTransaction<P>]()
        for (i, object) in _data.enumerated() {
            let transaction = CacheTransaction<P>(model: object, index: nil, newIndex: i, type:.insert)
            transactions.append(transaction)
        }
        return transactions
    }
}
