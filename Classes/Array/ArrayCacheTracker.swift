//
//  CoreDataCacheTracker.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation

public protocol ArrayCacheTrackerElement {
    func evaluate(_ predicate: NSPredicate) -> Bool
    static func sort(_ descriptors: [NSSortDescriptor], lhs: Self, rhs: Self) -> Bool
}

open class ArrayCacheTracker<P: ArrayCacheTrackerElement & CacheTrackerPlainModel>: CacheTracker {
    
    open var fetchLimitThreshold: Int = 0

    fileprivate var _cacheRequest: CacheRequest!
    fileprivate var _transactions: [CacheTransaction<P>]!
    fileprivate var _initialData: [P]
    fileprivate var _data: [P]!
    
    public init(data: [P]) {
        self._initialData = data.map({ $0 })
    }
    
    // MARK: - CacheTracker
    
    open weak var delegate: CacheTrackerDelegate?
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest, cacheName: String? = nil) -> Void {
        _cacheRequest = cacheRequest
        let filtered = _initialData.filter({ $0.evaluate(_cacheRequest.predicate) })//  (_initialData as NSArray).filtered(using: _cacheRequest.predicate)
        _data = _cacheRequest.sortDescriptors.isEmpty ? filtered : filtered.sorted(by: { (a, b) -> Bool in
            return P.sort(_cacheRequest.sortDescriptors, lhs: a, rhs: b)
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
