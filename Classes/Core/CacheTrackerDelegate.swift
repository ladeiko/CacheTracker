//
//  CacheTrackerDelegate.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

import Foundation

public protocol CacheTrackerDelegate: class {
    func cacheTrackerShouldMakeInitialReload()
    func cacheTrackerBeginUpdates()
    func cacheTrackerDidGenerate<P>(transactions: [CacheTransaction<P>])
    func cacheTrackerEndUpdates()
}

