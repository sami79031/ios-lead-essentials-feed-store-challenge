//
//  FeedStoreIntegrationTests.swift
//  Tests
//
//  Created by Caio Zullo on 01/09/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge


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
        let storeToInsert = makeSUT()
        let storeToOverride = makeSUT()
        let storeToLoad = makeSUT()
        
        insert((uniqueImageFeed(), Date()), to: storeToInsert)
        
        let latestFeed = uniqueImageFeed()
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), to: storeToOverride)
        
        expect(storeToLoad, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_delete_deletesFeedInsertedOnAnotherInstance() {
        let storeToInsert = makeSUT()
        let storeToDelete = makeSUT()
        let storeToLoad = makeSUT()
        
        insert((uniqueImageFeed(), Date()), to: storeToInsert)
        
        deleteCache(from: storeToDelete)
        
        expect(storeToLoad, toRetrieve: .empty)
    }
    
    // - MARK: Helpers
    
    private func makeSUT() -> FeedStore {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        let sut = try! CoreDataFeedStore(storeURL: self.storeURL, bundle: bundle)
        trackForMemoryLeak(sut)
        return sut
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
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Model.store")
    }
    
    
    
}
