//
//  CoreDataCacheTracker.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation

open class ArrayCacheTracker<P: CacheTrackerPlainModel>: CacheTracker {

    public typealias ArrayCacheTrackerFilter = (_ request: CacheRequest, _ item: P) -> Bool
    
    fileprivate var _cacheRequest: CacheRequest!
    fileprivate var _transactions: [CacheTransaction<P>]!
    fileprivate let _filter: ArrayCacheTrackerFilter
    fileprivate var _initialData: [P]
    fileprivate var _data: [P]!
    
    public init(data: [P], filter: @escaping ArrayCacheTrackerFilter) {
        self._initialData = data.map({ $0 })
        self._filter = filter
    }
    
    // MARK: - CacheTracker
    
    open weak var delegate: CacheTrackerDelegate?
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest, cacheName: String? = nil) -> Void {
        _cacheRequest = cacheRequest
        _data = _initialData.filter({ (model) -> Bool in
            return _filter(_cacheRequest, model)
        })
        if _cacheRequest.fetchLimit > 0 {
            _data = [P](_data[0..<_cacheRequest.fetchLimit])
        }
        delegate?.cacheTrackerShouldMakeInitialReload()
    }
    
    open func stopFetching() {
        // TODO
    }
    
    open func deleteCache(withName name: String?) {
        
    }
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest) -> Void {
        fetchWithRequest(cacheRequest, cacheName: nil)
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
