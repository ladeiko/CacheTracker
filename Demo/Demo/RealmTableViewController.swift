//
//  RealmTableViewController.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/13/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import CacheTracker
import RealmSwift

class RealmTableViewController: UITableViewController, CacheTrackerDelegate {

    var context: Realm!
    var cacheTracker: RealmCacheTracker<RealmItem, PlainItem>!
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                let value = UInt.random() % 4
                
                switch value {
                
                case 0:
                    
                    try! self.context.write {
                        
                        let count = self.context.objects(RealmItem.self).count
                        if count < 5 {
                            return
                        }
                        
                        let target = abs(Int.random()) % count
                        let objects = self.context.objects(RealmItem.self)
                        if target >= objects.count {
                            return
                        }
                        
                        self.context.delete(objects[target])
                    }
                    
                case 1: // update
                    try! self.context.write {
                        
                        let count = self.context.objects(RealmItem.self).count
                        if count < 5 {
                            return
                        }
                        
                        let target = abs(Int.random()) % count
                        let objects = self.context.objects(RealmItem.self)
                        if target >= objects.count {
                            return
                        }
                        
                        let object = objects[target]
                        object.name = String(abs(Int.random()))
                    }
                    
                default:
                    
                    try! self.context.write {
                        
                        let count = self.context.objects(RealmItem.self).count
                        if count > 10 {
                            return
                        }
                        
                        let item = RealmItem()
                        
                        item.idKey = String(Int.random())
                        item.name = String(abs(Int.random()))
                        
                        self.context.add(item)
                    }
                    
                }
                
                self.tabBarItem.badgeValue = String(self.context.objects(RealmItem.self).count)
            })
        }
        
        if context == nil {
            context = try! Realm()
        }
        
        try! context.write {
            context.deleteAll()
        }
        
        cacheTracker = RealmCacheTracker<RealmItem, PlainItem>(realm: context)
        cacheTracker.delegate = self
        let cacheRequest = CacheRequest(predicate: NSPredicate(value: true), sortDescriptors: [
            NSSortDescriptor(key: #keyPath(CoreDataItem.name), ascending: true)
            ])
        
        cacheTracker.fetchWithRequest(cacheRequest)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cacheTracker.numberOfObjects()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "Default")!
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = cacheTracker.object(at: indexPath.row)
        cell.textLabel?.text = item?.name
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - CacheTrackerDelegate
    func cacheTrackerShouldMakeInitialReload() {
        guard isViewLoaded else {
            return
        }
        
        tableView.reloadData()
    }
    
    func cacheTrackerBeginUpdates() {
        guard isViewLoaded else {
            return
        }
        
        tableView.beginUpdates()
    }
    
    func cacheTrackerEndUpdates() {
        guard isViewLoaded else {
            return
        }
        
        tableView.endUpdates()
    }
    
    func cacheTrackerDidGenerate<P>(transactions: [CacheTransaction<P>]) {
        
        guard isViewLoaded else {
            return
        }
        
        for transaction in transactions {
            switch transaction.type {
            case .insert:
                self.tableView.insertRows(at: [IndexPath(row: transaction.newIndex!, section: 0)], with: .fade)
            case .delete:
                self.tableView.deleteRows(at: [IndexPath(row: transaction.index!, section: 0)], with: .fade)
            case .update:
                self.tableView.reloadRows(at: [IndexPath(row: transaction.index!, section: 0)], with: .fade)
            case .move:
                self.tableView.deleteRows(at: [IndexPath(row: transaction.index!, section: 0)], with: .fade)
                self.tableView.insertRows(at: [IndexPath(row: transaction.newIndex!, section: 0)], with: .fade)
            }
        }
    }
}
