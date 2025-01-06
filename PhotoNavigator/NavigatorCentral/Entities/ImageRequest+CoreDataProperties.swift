//
//  ImageRequest+CoreDataProperties.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/5/24.
//
//

import Foundation
import CoreData


extension ImageRequest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageRequest> {
        return NSFetchRequest<ImageRequest>(entityName: "ImageRequest")
    }

    @NSManaged public var command: Int16
    @NSManaged public var filename: String?
    @NSManaged public var index: Int16

}

extension ImageRequest : Identifiable {

}
