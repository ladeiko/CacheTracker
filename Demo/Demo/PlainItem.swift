//
//  PlainItem.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/13/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import Foundation
import CacheTracker

class PlainItem: CacheTrackerPlainModel {
    
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    // MARK: - CacheTrackerPlainModel
    
    required init() {
        self.name = ""
    }

}
