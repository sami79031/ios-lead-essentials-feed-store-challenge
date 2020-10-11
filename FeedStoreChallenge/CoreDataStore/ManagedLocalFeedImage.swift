//
//  ManagedLocalFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Sami Ali on 10/11/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedLocalFeedImage)
internal class ManagedLocalFeedImage: NSManagedObject {
    @NSManaged internal var id: UUID
    @NSManaged internal var managed_description: String?
    @NSManaged internal var location: String?
    @NSManaged internal var url: URL
    @NSManaged internal var cache: Cache
}

extension ManagedLocalFeedImage {
    var localFeedImage: LocalFeedImage {
        return LocalFeedImage(id: id, description: managed_description, location: location, url: url)
    }
}
