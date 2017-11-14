//
//  CoreDataCollectionViewController.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/14/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import UIKit
import CacheTracker
import MagicalRecord
import RandomKit

class CoreDataCollectionViewController: UICollectionViewController, CacheTrackerDelegate {
    
    typealias P = PlainItem
    
    var context: NSManagedObjectContext!
    var cacheTracker: CoreDataCacheTracker<CoreDataItem, PlainItem>!
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                let value = Int.random(using: &Xoroshiro.default) % 4
                
                switch value {
                case 0:
                    self.context.mr_save( blockAndWait: { (context) in
                        if CoreDataItem.mr_countOfEntities(with: context) > 10 {
                            return
                        }
                        let value = UInt.random(using: &Xoroshiro.default)
                        let item = CoreDataItem.mr_createEntity(in: context)
                        item?.name = "\(value)"
                    })
                    
                case 1:
                    self.context.mr_save( blockAndWait: { (context) in
                        let items = CoreDataItem.mr_findAll(with: NSPredicate(value: true), in: context)!
                        let count = items.count
                        if  count > 1 {
                            let target = abs(Int.random(using: &Xoroshiro.default)) % count
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
                            let target = abs(Int.random(using: &Xoroshiro.default)) % count
                            let value = UInt.random(using: &Xoroshiro.default)
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
                let value = UInt.random(using: &Xoroshiro.default)
                item?.name = "\(value)"
            }
        })
        
        cacheTracker = CoreDataCacheTracker<CoreDataItem, PlainItem>(context: NSManagedObjectContext.mr_default())
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
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cacheTracker.numberOfObjects()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Default", for: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = cacheTracker.object(at: indexPath.row)
        let label = cell.viewWithTag(1) as! UILabel
        label.text = item?.name
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - CacheTrackerDelegate
    func cacheTrackerShouldMakeInitialReload() {
        guard isViewLoaded else {
            return
        }
        
        collectionView!.reloadData()
    }
    
    func cacheTrackerBeginUpdates() {
        guard isViewLoaded else {
            return
        }
        
        //tableView.beginUpdates()
    }
    
    func cacheTrackerEndUpdates() {
        guard isViewLoaded else {
            return
        }
        
        //tableView.endUpdates()
    }
    
    func cacheTrackerDidGenerate<P>(transactions: [CacheTransaction<P>]) {
        
        guard isViewLoaded else {
            return
        }
        
        collectionView?.performBatchUpdates({
            
            for transaction in transactions {
                switch transaction.type {
                case .insert:
                    self.collectionView!.insertItems(at: [IndexPath(row: transaction.newIndex!, section: 0)])
                case .delete:
                    self.collectionView!.deleteItems(at: [IndexPath(row: transaction.index!, section: 0)])
                case .update:
                    self.collectionView?.reloadItems(at: [IndexPath(row: transaction.index!, section: 0)])
                case .move:
                    self.collectionView!.deleteItems(at: [IndexPath(row: transaction.index!, section: 0)])
                    self.collectionView!.insertItems(at: [IndexPath(row: transaction.newIndex!, section: 0)])
                }
            }
            
        }, completion: { (completed) in
            
        })
        
    }
}

