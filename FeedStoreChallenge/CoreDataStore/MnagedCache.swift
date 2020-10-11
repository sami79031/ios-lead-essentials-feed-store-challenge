//
//  MnagedCache.swift
//  FeedStoreChallenge
//
//  Created by Sami Ali on 10/11/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import CoreData

@objc(Cache)
internal class Cache: NSManagedObject {
    @NSManaged internal var timestamp: Date
    @NSManaged internal var managedFeeds: NSOrderedSet
}

extension Cache {
    var managedFeedImages: [ManagedLocalFeedImage] {
        return managedFeeds.array as? [ManagedLocalFeedImage] ?? []
    }
    
    @nonobjc class func fetchCache(in context: NSManagedObjectContext) throws -> Cache? {
        let request = NSFetchRequest<Cache>(entityName: "Cache")
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    static func getUniqueManagedCache(in context: NSManagedObjectContext) -> Cache {
        if let managedCaches = try? fetchCache(in: context) {
            context.delete(managedCaches)
        }
        
        return Cache(context: context)
    }
}
