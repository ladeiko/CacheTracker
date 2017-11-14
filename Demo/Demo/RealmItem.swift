//
//  RealmItem.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/13/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import RealmSwift
import CacheTracker

class RealmItem: Object, CacheTrackerDatabaseModel {
    
    @objc dynamic var idKey = ""
    @objc dynamic var name = ""
    
    override static func primaryKey() -> String? {
        return "idKey"
    }
    
    // MARK: - CacheTrackerDatabaseModel
    
    static func entityName() -> String {
        return NSStringFromClass(self)
    }
    
    func toPlainModel<P>() -> P? {
        return PlainItem(name: self.name) as? P
    }
    
}
