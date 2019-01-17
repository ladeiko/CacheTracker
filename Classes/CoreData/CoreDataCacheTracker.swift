//
//  CoreDataCacheTracker.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation
import CoreData
import HeckelDiff

open class CoreDataCacheTracker<D: CacheTrackerDatabaseModel, P: CacheTrackerPlainModel>: NSObject, CacheTracker, NSFetchedResultsControllerDelegate {

    fileprivate var _controller: NSFetchedResultsController<NSFetchRequestResult>!
    fileprivate var _cacheRequest: CacheRequest!
    fileprivate var _context: NSManagedObjectContext!
    fileprivate var _transactions: [CacheTransaction<P>]!

    public init(context: NSManagedObjectContext) {
        super.init()
        self._context = context
    }
    
    // MARK: - CacheTracker
    
    open var fetchLimitThreshold: Int = 0
    
    open var enableFetchLimitOverflowSoftNormalizer: Bool = false
    
    open weak var delegate: CacheTrackerDelegate?
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest, cacheName: String? = nil) -> Void {
        _cacheRequest = cacheRequest
        let fetchRequest = self._fetchRequestWithCacheRequest(cacheRequest)
        _controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                 managedObjectContext: _context,
                                                 sectionNameKeyPath: nil,
                                                 cacheName: cacheName)
        
        _controller.delegate = self
        
        try! _controller.performFetch()
        delegate?.cacheTrackerShouldMakeInitialReload()
    }
    
    open func stopFetching() {
        _controller.delegate = nil
        _controller = nil
    }
    
    open func deleteCache(withName name: String?) {
        NSFetchedResultsController<NSManagedObject>.deleteCache(withName: name)
    }
    
    open func fetchWithRequest(_ cacheRequest: CacheRequest) -> Void {
        fetchWithRequest(cacheRequest, cacheName: nil)
    }
    
    open func object(at index: Int) -> P? {
        let anObject = _controller.object(at: IndexPath(row: index, section: 0)) as! D
        return anObject.toPlainModel()
    }
    
    open func numberOfObjects() -> Int {
        guard let sections = _controller.sections else {
            return 0
        }
        guard sections.isEmpty == false else {
            return 0
        }
        return sections[0].numberOfObjects
    }
    
    open func object(at indexPath: IndexPath) -> P? {
        let anObject = _controller.object(at: indexPath) as! D
        return anObject.toPlainModel()
    }
    
    open func allObjects() -> [P] {
        return _controller.fetchedObjects!.map { (anObject) -> AnyObject? in
            let anObject = anObject as! D
            return anObject.toPlainModel()
        } as! [P]
    }
    
    open func transactionsForCurrentState() -> [CacheTransaction<P>] {
        var transactions = [CacheTransaction<P>]()
        for (_, object) in _controller.fetchedObjects!.enumerated() {
            let indexPath = _controller.indexPath(forObject: object)!
            let object = object as! D
            let model: P = object.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: nil, newIndex: indexPath.row, type:.insert)
            transactions.append(transaction)
        }
        return transactions
    }

    // MARK: - NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        _transactions = [CacheTransaction]()
        delegate?.cacheTrackerBeginUpdates()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for changeType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard var actualType = NSFetchedResultsChangeType(rawValue: changeType.rawValue) else {
            // This fix is for a bug where iOS passes 0 for NSFetchedResultsChangeType, but this is not a valid enum case.
            // Swift will then always execute the first case of the switch causing strange behaviour.
            // https://forums.developer.apple.com/thread/12184#31850
            return
        }
        
        // This whole dance is a workaround for a nasty bug introduced in XCode 7 targeted at iOS 8 devices
        // http://stackoverflow.com/questions/31383760/ios-9-attempt-to-delete-and-reload-the-same-index-path/31384014#31384014
        // https://forums.developer.apple.com/message/9998#9998
        // https://forums.developer.apple.com/message/31849#31849
        if #available(iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            
            // I don't know if iOS 10 even attempted to fix this mess...
            if case .update = actualType,
                indexPath != nil,
                newIndexPath != nil {
                
                actualType = .move
            }
        }
        
        var actualIndexPath = indexPath
        var actualNewIndexPath = newIndexPath
    
        switch actualType {
        case .insert:
            guard indexPath == nil else { //fix iOS8 bug
                return
            }
        case .update: break
        case .move:
            
            guard indexPath != nil && newIndexPath != nil else {
                return
            }
            
            guard indexPath == newIndexPath else {
                break
            }
            
            guard #available(iOS 9.0, tvOS 9.0, watchOS 9.0, *) else {
                return
            }
            
            actualType = .update
            actualNewIndexPath = nil
            
        default:
            break
        }
        
        let anObject = anObject as! D
        
        switch actualType {
        case .insert:
            let model: P = anObject.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: nil, newIndex: actualNewIndexPath!.row, type: .insert)
            _transactions.append(transaction)
            
        case .delete:
            let transaction = CacheTransaction<P>(model: nil, index: actualIndexPath!.row, newIndex: nil, type: .delete)
            _transactions.append(transaction)
            
        case .update:
            let model: P = anObject.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: actualIndexPath!.row, newIndex: nil, type: .update)
            _transactions.append(transaction)
            
        case .move:
            let model: P = anObject.toPlainModel()!
            let transaction = CacheTransaction<P>(model: model, index: actualIndexPath!.row, newIndex: actualNewIndexPath!.row, type:.move)
            _transactions.append(transaction)
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        defer {
            _transactions = nil
            delegate?.cacheTrackerEndUpdates()
            
            // HACK, try create more elegant solution in future
            if _cacheRequest.fetchLimit > 0, let fetchedObjects = _controller.fetchedObjects, fetchedObjects.count > (_cacheRequest.fetchLimit + fetchLimitThreshold) {
                
                try! _controller.performFetch()
                
                if enableFetchLimitOverflowSoftNormalizer {
                    
                    let oldObjects = fetchedObjects as! [NSManagedObject]
                    let newObjects = _controller.fetchedObjects as! [NSManagedObject]

                    let oldItems = oldObjects.map { (o) -> String in
                        return o.objectID.uriRepresentation().absoluteString
                    }
                    
                    let newItems = newObjects.map { (o) -> String in
                        return o.objectID.uriRepresentation().absoluteString
                    }
                    
                    var diffTransactions = [CacheTransaction<P>]()
                    
                    let result = diff(oldItems, newItems)
                    
                    result.forEach { (operation) in
                        switch operation {
                        
                        case .update(let index):
                            let anObject = newObjects[index] as! D
                            let model: P = anObject.toPlainModel()!
                            let transaction = CacheTransaction<P>(model: model, index: index, newIndex: nil, type: .update)
                            diffTransactions.append(transaction)
                            
                        case .delete(let index):
                            let transaction = CacheTransaction<P>(model: nil, index: index, newIndex: nil, type: .delete)
                            diffTransactions.append(transaction)
                            
                        case .insert(let index):
                            let anObject = newObjects[index] as! D
                            let model: P = anObject.toPlainModel()!
                            let transaction = CacheTransaction<P>(model: model, index: nil, newIndex: index, type: .insert)
                            diffTransactions.append(transaction)
                            
                        case .move(let from, let to):
                            let anObject = oldObjects[from] as! D
                            let model: P = anObject.toPlainModel()!
                            let transaction = CacheTransaction<P>(model: model, index: from, newIndex: to, type:.move)
                            diffTransactions.append(transaction)
                        }
                    }
                    
                    delegate?.cacheTrackerBeginUpdates()
                    delegate?.cacheTrackerDidGenerate(transactions: diffTransactions)
                    delegate?.cacheTrackerEndUpdates()
                }
                else {
                    delegate?.cacheTrackerShouldMakeInitialReload()
                }
            }
        }
        
        guard _transactions.isEmpty == false else { //fix iOS8/9 bug: count maybe 0
            return
        }
        
        delegate?.cacheTrackerDidGenerate(transactions: _transactions)
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return nil
    }
}

extension CoreDataCacheTracker {
    
    fileprivate static func _changeType(from coreDataChangeType: NSFetchedResultsChangeType) -> CacheTransactionType {
        switch coreDataChangeType {
        case .insert: return .insert
        case .update: return .update
        case .delete: return .delete
        case .move: return .move
        }
    }
    
    fileprivate func _fetchRequestWithCacheRequest(_ cacheRequest: CacheRequest) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: D.entityName())
        fetchRequest.predicate = cacheRequest.predicate
        fetchRequest.sortDescriptors = cacheRequest.sortDescriptors
        if cacheRequest.fetchLimit > 0 {
            fetchRequest.fetchLimit = cacheRequest.fetchLimit
        }
        return fetchRequest
    }
    
}
