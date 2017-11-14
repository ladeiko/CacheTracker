//
//  RealmCollectionViewController.swift
//  Demo
//
//  Created by Siarhei Ladzeika on 11/14/17.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

import CacheTracker
import RealmSwift
import RandomKit

class RealmCollectionViewController: UICollectionViewController, CacheTrackerDelegate {
    
    var context: Realm!
    var cacheTracker: RealmCacheTracker<RealmItem, PlainItem>!
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
                let value = Int.random(using: &Xoroshiro.default) % 4
                
                switch value {
                    
                case 0:
                    
                    try! self.context.write {
                        
                        let count = self.context.objects(RealmItem.self).count
                        if count < 5 {
                            return
                        }
                        
                        let target = abs(Int.random(using: &Xoroshiro.default)) % count
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
                        
                        let target = abs(Int.random(using: &Xoroshiro.default)) % count
                        let objects = self.context.objects(RealmItem.self)
                        if target >= objects.count {
                            return
                        }
                        
                        let object = objects[target]
                        object.name = String(abs(Int.random(using: &Xoroshiro.default)))
                    }
                    
                default:
                    
                    try! self.context.write {
                        
                        let count = self.context.objects(RealmItem.self).count
                        if count > 10 {
                            return
                        }
                        
                        let item = RealmItem()
                        
                        item.idKey = String(Int.random(using: &Xoroshiro.default))
                        item.name = String(abs(Int.random(using: &Xoroshiro.default)))
                        
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
