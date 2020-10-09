//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Sami Ali on 10/8/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(withModelName: "Model", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        fatalError("Not omplemented")
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        
        context.perform {
            let cache = Cache.getUniqueManagedCache(in: context)
            cache.timestamp = timestamp
            cache.managedFeeds = feed.mapToManagedFeedImages(in: context).toNSOrderedSet
            try! context.save()
            completion(nil)
        }
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        
        context.perform {
            guard let managedCaches = try? context.fetch(Cache.fetchRequest() as NSFetchRequest<Cache>),
                  let firstObject = managedCaches.first,
                  let timestamp = firstObject.timestamp else {
                
                return completion(.empty)
            }
            
            let localFeedImages = firstObject.managedFeedImages.map( {$0.localFeedImage} )
            completion(.found(feed: localFeedImages, timestamp: timestamp))
        }
    }
    
    private func deleteAllData(entity: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try! context.execute(batchDeleteRequest) as! NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [
            NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
        ]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
    
}

