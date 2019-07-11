//
//  MultiCachtrackerExample.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 7/11/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import Foundation
import CacheTracker
import MagicalRecord

class MultiCachtrackerExample: CacheTrackerDelegateProxyDelegate {
    
    typealias P = PlainItem
    
    var tracker1: CoreDataCacheTracker<CoreDataItem, PlainItem>!
    var tracker2: CoreDataCacheTracker<CoreDataItem, PlainItem>!
    let proxy1 = CacheTrackerDelegateProxy()
    let proxy2 = CacheTrackerDelegateProxy()
    
    init() {
        proxy1.delegate = self
        proxy2.delegate = self
        
        tracker1 = CoreDataCacheTracker<CoreDataItem, PlainItem>(context: NSManagedObjectContext.mr_default())
        tracker1.delegate = proxy1
        tracker1.fetchWithRequest(CacheRequest(predicate: NSPredicate(value: true), sortDescriptors: [
            NSSortDescriptor(key: #keyPath(CoreDataItem.name), ascending: true)
            ], fetchLimit: 5))
        
        tracker2 = CoreDataCacheTracker<CoreDataItem, PlainItem>(context: NSManagedObjectContext.mr_default())
        tracker2.delegate = proxy2
        tracker2.fetchWithRequest(CacheRequest(predicate: NSPredicate(value: true), sortDescriptors: [
            NSSortDescriptor(key: #keyPath(CoreDataItem.name), ascending: true)
            ], fetchLimit: 5))
    }
    
    // MARK: - CacheTrackerDelegateProxyDelegate
    
    func cacheTrackerShouldMakeInitialReload(_ proxy: CacheTrackerDelegateProxy) {
        if proxy1 === proxy {
            // TODO
        }
        else if proxy2 === proxy {
            // TODO
        }
        else {
            assert(false)
        }
    }
    
    func cacheTrackerDidGenerate<P>(_ proxy: CacheTrackerDelegateProxy, transactions: [CacheTransaction<P>]) {
        if proxy1 === proxy {
            // TODO
        }
        else if proxy2 === proxy {
            // TODO
        }
        else {
            assert(false)
        }
    }
    
    func cacheTrackerBeginUpdates(_ proxy: CacheTrackerDelegateProxy) {
        if proxy1 === proxy {
            // TODO
        }
        else if proxy2 === proxy {
            // TODO
        }
        else {
            assert(false)
        }
    }
    
    func cacheTrackerEndUpdates(_ proxy: CacheTrackerDelegateProxy) {
        if proxy1 === proxy {
            // TODO
        }
        else if proxy2 === proxy {
            // TODO
        }
        else {
            assert(false)
        }
    }
    
}
