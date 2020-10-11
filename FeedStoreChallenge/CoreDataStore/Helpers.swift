//
//  Helpers.swift
//  FeedStoreChallenge
//
//  Created by Sami Ali on 10/8/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData


internal extension Array {
    var toNSOrderedSet: NSOrderedSet {
        return NSOrderedSet(array: self)
    }
}

internal extension Array where Element == LocalFeedImage {
    
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

internal extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        guard let url = bundle.url(forResource: name, withExtension: "momd") else {
            return nil
        }
        
        return NSManagedObjectModel(contentsOf: url)
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
