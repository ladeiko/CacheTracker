//
//  CacheRequest.swift
//
//  Created by Siarhei Ladzeika.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//
//  Based on https://github.com/akantsevoi/CacheTracker
//

import Foundation

//struct TodoItem {
//    let isCompleted: Bool
//    let dueDate: Date
//}
//
//extension TodoList {
//    func items(matching predicate: Predicate<TodoItem>) -> [TodoItem] {
//        items.filter(predicate.matches)
//    }
//}
//
//extension CacheRequestArrayPredicate where Target == TodoItem {
//    static var isOverdue: Self {
//        Predicate {
//            !$0.isCompleted && $0.dueDate < .now
//        }
//    }
//}
//
//let overdueItems = list.items(matching: .isOverdue)

public class CacheRequest {

    @available(*, deprecated, message: "Please try to not use this property")
    public let predicate: NSPredicate!

    @available(*, deprecated, message: "Please try to not use this property")
    public let sortDescriptors: [NSSortDescriptor]!

    @available(*, deprecated, message: "Please try to not use this property")
    public let fetchLimit: Int!

    @available(*, deprecated, message: "Please create request with CacheRequest.databaseRequest(...)")
    public init(predicate: NSPredicate = .init(value: true),
                sortDescriptors: [NSSortDescriptor] = [],
                fetchLimit: Int = 0) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
    }

    public static func databaseRequest(predicate: NSPredicate = .init(value: true),
                                       sortDescriptors: [NSSortDescriptor] = [],
                                       fetchLimit: Int = 0) -> CacheRequest {
        DatabaseCacheRequest(predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: fetchLimit)
    }

    public static func arrayRequest<T>(filter: ArrayCacheRequestFilter<T>? = nil,
                                       comparator: ArrayCacheRequestComparator<T>? = nil,
                                       range: Range<Int>? = nil) -> CacheRequest {
        ArrayCacheRequest(filter: filter, comparator: comparator, range: range)
    }
}
