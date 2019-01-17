//
//  CoreDataTableViewController.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/10/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import UIKit
import CacheTracker
import MagicalRecord

class CoreDataTableViewController: UITableViewController, CacheTrackerDelegate {
    
    typealias P = PlainItem
    
    var context: NSManagedObjectContext!
    var cacheTracker: CoreDataCacheTracker<CoreDataItem, PlainItem>!
    var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                let value = UInt.random() % 4
                
                switch value {
                case 0:
                    self.context.mr_save( blockAndWait: { (context) in
                        if CoreDataItem.mr_countOfEntities(with: context) > 10 {
                            return
                        }
                        let value = UInt.random()
                        let item = CoreDataItem.mr_createEntity(in: context)
                        item?.name = "\(value)"
                    })
                    
                case 1:
                    self.context.mr_save( blockAndWait: { (context) in
                        let items = CoreDataItem.mr_findAll(with: NSPredicate(value: true), in: context)!
                        let count = items.count
                        if  count > 1 {
                            let target = abs(Int.random()) % count
                            items[target].mr_deleteEntity(in: context)
                        }
                    })
                    
                case 2:
                   break
                    
                default:
                    self.context.mr_save( blockAndWait: { (context) in
                        let items = CoreDataItem.mr_findAll(with: NSPredicate(value: true), in: context)!
                        let count = items.count
                        if  count > 1 {
                            let target = abs(Int.random()) % count
                            let value = UInt.random()
                            let item = items[target] as! CoreDataItem
                            item.name = "\(value)"
                        }
                    })
                }
             
                self.tabBarItem.badgeValue = String(CoreDataItem.mr_countOfEntities())
            })
        }
        
        if context == nil {
             context = NSManagedObjectContext.mr_default()
        }
        
        context.mr_save( blockAndWait: { (context) in
            CoreDataItem.mr_deleteAll(matching: NSPredicate(value: true), in: context)
            for _ in 0..<3 {
                let item = CoreDataItem.mr_createEntity(in: context)
                let value = UInt.random()
                item?.name = "\(value)"
            }
        })
        
        cacheTracker = CoreDataCacheTracker<CoreDataItem, PlainItem>(context: NSManagedObjectContext.mr_default())
        cacheTracker.delegate = self
        let cacheRequest = CacheRequest(predicate: NSPredicate(value: true), sortDescriptors: [
            NSSortDescriptor(key: #keyPath(CoreDataItem.name), ascending: true)
            ], fetchLimit: 5)
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

