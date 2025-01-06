//
//  MediaFile+CoreDataProperties.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/5/24.
//
//

import Foundation
import CoreData


extension MediaFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaFile> {
        return NSFetchRequest<MediaFile>(entityName: "MediaFile")
    }

    @NSManaged public var filename: String?
    @NSManaged public var relativePath: String?
    @NSManaged public var guid: String?
    @NSManaged public var keywords: String?

}

extension MediaFile : Identifiable {

}
