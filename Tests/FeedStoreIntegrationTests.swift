//
//  FeedStoreIntegrationTests.swift
//  Tests
//
//  Created by Caio Zullo on 01/09/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData

private class CoreDataFeedStore: FeedStore {
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(withModelName: "Model", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        fatalError("Not omplemented")
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let cache = Cache(context: context)
        cache.timestamp = timestamp
        cache.managedFeeds = feed.mapToManagedFeedImages(in: context).toNSOrderedSet
        
        try! context.save()
        completion(nil)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let managedCaches = try? context.fetch(Cache.fetchRequest() as NSFetchRequest<Cache>),
              let firstObject = managedCaches.first,
              let timestamp = firstObject.timestamp else {
            
            return completion(.empty)
        }
        
        let localFeedImages = firstObject.managedFeedImages.map({$0.localFeedImage})
        completion(.found(feed: localFeedImages, timestamp: timestamp))
    }
    
    
}

private extension ManagedLocalFeedImage {
    var localFeedImage: LocalFeedImage {
        return LocalFeedImage(id: id!, description: managed_description, location: location, url: url!)
    }
}

internal extension NSPersistentContainer {
    enum LoadError: Swift.Error {
        case didNotFindModel
        case didFailToLoadPersistentStores(Swift.Error)
    }
    
    static func load(withModelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let managedObjectModel = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadError.didNotFindModel
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
        
        var loadError: Swift.Error?
        
        let description = NSPersistentStoreDescription(url: url)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (_, error) in
            loadError = error
        }
        
        try loadError.map({ throw LoadError.didFailToLoadPersistentStores($0)})
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        guard let url = bundle.url(forResource: name, withExtension: "momd") else {
            return nil
        }
        
        return NSManagedObjectModel(contentsOf: url)
    }
}

private extension Cache {
    var managedFeedImages: [ManagedLocalFeedImage] {
        return managedFeeds?.array as? [ManagedLocalFeedImage] ?? []
    }
}

private extension Array where Element == LocalFeedImage {
    
    func mapToManagedFeedImages(in context: NSManagedObjectContext) -> [ManagedLocalFeedImage] {
        
        let managedFeedArray = self.map { (localImage) -> ManagedLocalFeedImage in
            let managedFeedImage = ManagedLocalFeedImage(context: context)
            managedFeedImage.id = localImage.id
            managedFeedImage.managed_description = localImage.description
            managedFeedImage.location = localImage.location
            managedFeedImage.url = localImage.url
            return managedFeedImage
        }
        
        return managedFeedArray
    }
}

private extension Array {
    var toNSOrderedSet: NSOrderedSet {
        return NSOrderedSet(array: self)
    }
}


class FeedStoreIntegrationTests: XCTestCase {
    
    //  ***********************
    //
    //  Uncomment and implement the following tests if your
    //  implementation persists data to disk (e.g., CoreData/Realm)
    //
    //  ***********************
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_deliversFeedInsertedOnAnotherInstance() {
        let storeToInsert = makeSUT()
        let storeToLoad = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        insert((feed, timestamp), to: storeToInsert)
        
        expect(storeToLoad, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_insert_overridesFeedInsertedOnAnotherInstance() {
        //        let storeToInsert = makeSUT()
        //        let storeToOverride = makeSUT()
        //        let storeToLoad = makeSUT()
        //
        //        insert((uniqueImageFeed(), Date()), to: storeToInsert)
        //
        //        let latestFeed = uniqueImageFeed()
        //        let latestTimestamp = Date()
        //        insert((latestFeed, latestTimestamp), to: storeToOverride)
        //
        //        expect(storeToLoad, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_delete_deletesFeedInsertedOnAnotherInstance() {
        //        let storeToInsert = makeSUT()
        //        let storeToDelete = makeSUT()
        //        let storeToLoad = makeSUT()
        //
        //        insert((uniqueImageFeed(), Date()), to: storeToInsert)
        //
        //        deleteCache(from: storeToDelete)
        //
        //        expect(storeToLoad, toRetrieve: .empty)
    }
    
    // - MARK: Helpers
    
    private func makeSUT() -> FeedStore {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        return try! CoreDataFeedStore(storeURL: self.storeURL, bundle: bundle)
    }
    
    private func setupEmptyStoreState() {
        removePersistentStoreItExists()
    }
    
    private func undoStoreSideEffects() {
        removePersistentStoreItExists()
    }
    
    private func removePersistentStoreItExists() {
        let url = self.storeURL
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                XCTFail("Failed to remove Model.store with error: \(error)")
            }
        }
    }
    
    private var storeURL: URL {
        return try! FileManager
            .default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Model.store")
    }
    
    
    
}
