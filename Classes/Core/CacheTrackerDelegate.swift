//
//  CacheTrackerDelegate.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

import Foundation

public protocol CacheTrackerDelegate: AnyObject {
    func cacheTrackerShouldMakeInitialReload()
    func cacheTrackerBeginUpdates()
    func cacheTrackerDidGenerate<P>(transactions: [CacheTransaction<P>])
    func cacheTrackerEndUpdates()
}

/**
 *  Can be used when you want to use multiple cache trackers in single class
 *  in this case you can create two CacheTrackerDelegateProxy objects make them
 *  delegates for corresponding trackers and in their delegates identify them by pointers
 */
public protocol CacheTrackerDelegateProxyDelegate: AnyObject {
    func cacheTrackerShouldMakeInitialReload(_ proxy: CacheTrackerDelegateProxy)
    func cacheTrackerBeginUpdates(_ proxy: CacheTrackerDelegateProxy)
    func cacheTrackerDidGenerate<P>(_ proxy: CacheTrackerDelegateProxy, transactions: [CacheTransaction<P>])
    func cacheTrackerEndUpdates(_ proxy: CacheTrackerDelegateProxy)
}

public class CacheTrackerDelegateProxy: CacheTrackerDelegate {
    
    public weak var delegate: CacheTrackerDelegateProxyDelegate?
    
    public init(){}
    
    // MARK: - CacheTrackerDelegate
    
    public func cacheTrackerShouldMakeInitialReload() {
        delegate?.cacheTrackerShouldMakeInitialReload(self)
    }
    
    public func cacheTrackerBeginUpdates() {
        delegate?.cacheTrackerBeginUpdates(self)
    }
    
    public func cacheTrackerDidGenerate<P>(transactions: [CacheTransaction<P>]) {
        delegate?.cacheTrackerDidGenerate(self, transactions: transactions)
    }
    
    public func cacheTrackerEndUpdates() {
        delegate?.cacheTrackerEndUpdates(self)
    }
}
