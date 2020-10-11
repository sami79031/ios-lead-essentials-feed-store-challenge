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
        let possibleDeleteError = deleteAllCachedData()
        completion(possibleDeleteError)
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        
        context.perform {
            let cache = Cache.getUniqueManagedCache(in: context)
            cache.timestamp = timestamp
            cache.managedFeeds = feed.mapToManagedFeedImages(in: context).toNSOrderedSet
            
            do {
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        
        context.perform {
            
            do {
                guard let managedCache = try context.fetch(Cache.fetchRequest() as NSFetchRequest<Cache>).first else {
                    return completion(.empty)
                }
                let timestamp = managedCache.timestamp ?? Date()
                let localFeedImages = managedCache.managedFeedImages.map( {$0.localFeedImage} )
                completion(.found(feed: localFeedImages, timestamp: timestamp))
            } catch {
                completion(.failure(error))
            }
            
        }
    }
    
    private func deleteAllCachedData() -> Error? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cache")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(batchDeleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            return nil
        } catch {
            return error
        }
        
    }
    
}

