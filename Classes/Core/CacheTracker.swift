//
//  CacheTracker.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

public protocol CacheTracker: AnyObject {
    
    associatedtype P: CacheTrackerPlainModel
    
    var delegate: CacheTrackerDelegate? { get set }
    
    /**
         Starts fetching of objects associated with passed cache request.
     
         @param cacheRequest cache request containing predicate and sort descriptors.
     
         @param cacheName name of the cache to be used while fetching results.
     */
    func fetchWithRequest(_ cacheRequest: CacheRequest, cacheName: String?)
    
    /**
         See description of 'func fetchWithRequest(_ cacheRequest: CacheRequest, sectionNameKeyPath: String?, cacheName: String?)'
     */
    func fetchWithRequest(_ cacheRequest: CacheRequest)
    
    /**
         Stop fetching initiated with one of the 'fetchWithRequest' methods.
     */
    func stopFetching()
    
    /**
         Deletes cache with specified name.
     
         @param withName name of cache to be deleted.
     */
    func deleteCache(withName name: String?)
    
    /**
         Returns model object (database object already converted to model) at specified index.
     
         @param at - linear index of object (only one section is used)
     
         @return model object
     */
    func object(at index: Int) -> P?
    
    /**
         Returns batch of CacheTransaction objects fro current state of cache.
         This can be used to make initial setup of UI.
     
         @return NSArray of CacheTransaction
     */
    func transactionsForCurrentState() -> [CacheTransaction<P>]
    
    /**
         Returns total number of objects found by fetch request.
     
         @return Number of objects
     */
    func numberOfObjects() -> Int
    
    /**
         Returns all model objects found by fetch request.
     
         @return NSArray of model objects
     */
    func allObjects() -> [P]
    
    /**
        Defaults to 0
        Value controls situation when controller fetched more objects
        than required by fetchLimit in request.
    */
    var fetchLimitThreshold: Int { set get }
}
