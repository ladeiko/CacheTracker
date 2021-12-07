//
//  RealmCacheTracker.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation
import RealmSwift
import SafeRealmObjectX
import RBQFetchedResultsControllerX

open class RealmCacheTracker<D: Object & CacheTrackerDatabaseModel, P: CacheTrackerPlainModel>: NSObject, CacheTracker, RealmFetchedResultsControllerDelegate {
 
    open weak var delegate: CacheTrackerDelegate?
    
    fileprivate var _controller: RealmFetchedResultsController<D>!
    fileprivate var _cacheRequest: CacheRequest!
    fileprivate var _transactions: [CacheTransaction<P>]!
    fileprivate var _realm: Realm!
    
    public init(realm: Realm) {
        super.init()
        self._realm = realm
    }

    // MARK: - CacheTracker
    
    open var fetchLimitThreshold: Int = 0
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest, cacheName: String? = nil) -> Void {
        _cacheRequest = cacheRequest
        let fetchRequest = self._fetchRequestWithCacheRequest(cacheRequest)
        _controller = RealmFetchedResultsController(fetchRequest: fetchRequest,
                                                 sectionNameKeyPath: nil,
                                                 cacheName: cacheName)
        
        _controller.logging = false
        _controller.delegate = self
        
        let _ = self._controller.performFetch()
    }
    
    open func stopFetching() {
        _controller.delegate = nil
        _controller = nil
    }
    
    open func deleteCache(withName name: String?) {
        if let name = name {
            RealmFetchedResultsController.deleteCache(name)
        }
    }
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest) -> Void {
        fetchWithRequest(cacheRequest, cacheName: nil)
    }
    
    open func numberOfObjects() -> Int {
        return _controller.numberOfRowsForSectionIndex(0)
    }
    
    open func object(at index: Int) -> P? {
        if let anObject = _controller.objectAtIndexPath(IndexPath(row: index, section: 0)) {
            return anObject.toPlainModel()
        }
        else {
            return nil
        }
    }
    
    open func allObjects() -> [P] {
        let databaseItems = _controller.fetchedObjects
        return databaseItems.map { (anObject) -> P in
            return anObject.toPlainModel()!
        }
    }
    
    open func transactionsForCurrentState() -> [CacheTransaction<P>] {
        
        var transactions = [CacheTransaction<P>]()
        
        for (i, object) in _controller.fetchedObjects.enumerated() {
            let model: P = object.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: nil, newIndex: i, type:.insert)
            transactions.append(transaction)
        }
        
        return transactions
    }

    // MARK: - RealmFetchedResultsControllerDelegate
    
    func controllerWillChangeContent<T>(_ controller: RealmFetchedResultsController<T>) {
        _transactions = [CacheTransaction]()
        delegate?.cacheTrackerBeginUpdates()
    }
    
    func controller<T>(_ controller: RealmFetchedResultsController<T>, didChangeObject anObject: SafeObject<T>, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let actualIndexPath = indexPath
        let actualNewIndexPath = newIndexPath
        
        if type == .move {
            guard indexPath != newIndexPath else {
                return
            }
        }
        
        switch type {
        case .insert:
            let rbqSafeREalmObject = anObject.rbqSafeRealmObject
            let databaseItem = (rbqSafeREalmObject.rlmObject() as? D) ?? D()
            let model: P = databaseItem.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: nil, newIndex: actualNewIndexPath!.row, type: .insert)
            _transactions.append(transaction)
            
        case .delete:
            let transaction = CacheTransaction<P>(model: nil, index: actualIndexPath!.row, newIndex: nil, type: .delete)
            _transactions.append(transaction)
            
        case .update:
            let rbqSafeREalmObject = anObject.rbqSafeRealmObject
            let databaseItem = (rbqSafeREalmObject.rlmObject() as? D) ?? D()
            let model: P = databaseItem.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: actualIndexPath!.row, newIndex: nil, type: .update)
            _transactions.append(transaction)
            
        case .move:
            let rbqSafeREalmObject = anObject.rbqSafeRealmObject
            let databaseItem = (rbqSafeREalmObject.rlmObject() as? D) ?? D()
            let model: P = databaseItem.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: actualIndexPath!.row, newIndex: actualNewIndexPath!.row, type:.move)
            _transactions.append(transaction)
        }
    }
    
    func controllerDidChangeSection<T>(_ controller: RealmFetchedResultsController<T>, section: RealmFetchResultsSectionInfo<T>, sectionIndex: UInt, changeType: NSFetchedResultsChangeType) {
        
    }
    
    func controllerDidChangeContent<T>(_ controller: RealmFetchedResultsController<T>) {
        defer {
            _transactions = nil
            delegate?.cacheTrackerEndUpdates()
        }
        
        if _transactions.isEmpty {
            return
        }
        
        delegate?.cacheTrackerDidGenerate(transactions: _transactions)
    }
    
    func controllerWillPerformFetch<D>(_ controller: RealmFetchedResultsController<D>) {}
    
    func controllerDidPerformFetch<D>(_ controller: RealmFetchedResultsController<D>) {}

    // MARK: - Utils
    
    fileprivate static func _changeType(from coreDataChangeType: NSFetchedResultsChangeType) -> CacheTransactionType {
        switch coreDataChangeType {
        case .insert: return .insert
        case .update: return .update
        case .delete: return .delete
        case .move: return .move
            @unknown default:
                fatalError()
        }
    }
    
    fileprivate func _fetchRequestWithCacheRequest(_ cacheRequest: CacheRequest) -> CacheTrackerRealmFetchRequest<D> {
        let fetchRequest = CacheTrackerRealmFetchRequest<D>(realm: _realm, predicate: cacheRequest.predicate)
        fetchRequest.sortDescriptors = cacheRequest.sortDescriptors.map({ (sd) -> RealmSwift.SortDescriptor in
            return RealmSwift.SortDescriptor(keyPath: sd.key!, ascending: sd.ascending)
        })
        return fetchRequest
    }
    
}
