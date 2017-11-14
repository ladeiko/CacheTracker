# CacheTracker

Defines interfaces for helper dividing UI from storage layer. Also contains default implementation for CoreData adn Realm.

Tracker also make convertion of database model to plain one (so called PONSO). All you need is just implement some protocol in database model and in plain model classes.

Can be used in VIPER architecture inside interactor. In this case your code will work with PONSO object only.

**NOTE**: All interfaces work only with single section, all indexes are passed as single linear numbers, not IndexPath.

**NOTE**: Original idea was taken from [https://github.com/akantsevoi/CacheTracker](https://github.com/akantsevoi/CacheTracker)

## Usage

Define plain model class

```swift
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
```

Define database entity class

```swift
import CoreData
import CacheTracker

@objc(CoreDataItem)
class CoreDataItem: NSManagedObject, CacheTrackerDatabaseModel {
    
    @NSManaged var name: String?
    
    // MARK: - CacheTrackerDatabaseModel
    
    static func entityName() -> String {
        return NSStringFromClass(self)
    }
    
    func toPlainModel<P>() -> P? {
        return PlainItem(name: self.name!) as? P
    }
}
```

Just create cache request

```swift
let cacheRequest = CacheRequest(predicate: NSPredicate(value: true), sortDescriptors: [
	NSSortDescriptor(key: #keyPath(CoreDataItem.name), ascending: true)
])
```

Instantiate cache tracker with classes for database and PONSO model

```swift
cacheTracker = CoreDataCacheTracker<CoreDataItem, PlainItem>(context: NSManagedObjectContext.mr_default())
        cacheTracker.delegate = self
```

and start fetching

```swift
cacheTracker.fetchWithRequest(cacheRequest)
```

### CoreData + UITableView

```swift
import UIKit
import CacheTracker
import MagicalRecord
import RandomKit

class CoreDataTableViewController: UITableViewController, CacheTrackerDelegate {
    
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
```

### CoreData + UICollectionView

```swift
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
```

### Realm + UITableView

```swift
import CacheTracker
import RealmSwift
import RandomKit

class RealmTableViewController: UITableViewController, CacheTrackerDelegate {

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
```

### Realm + UICollectionView

```swift
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
```

## LICENSE

MIT License

Copyright (c) 2017 Siarhei Ladzeika

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
