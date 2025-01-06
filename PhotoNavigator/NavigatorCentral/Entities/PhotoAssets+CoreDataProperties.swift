//
//  PhotoAssets+CoreDataProperties.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 10/2/24.
//
//

import Foundation
import CoreData


extension PhotoAssets {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoAssets> {
        return NSFetchRequest<PhotoAssets>(entityName: "PhotoAssets")
    }

    @NSManaged public var identifiers: String?

}

extension PhotoAssets : Identifiable {

}
