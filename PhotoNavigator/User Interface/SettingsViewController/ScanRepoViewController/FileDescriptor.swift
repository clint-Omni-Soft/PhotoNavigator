//
//  FileDescriptor.swift
//  WineStock
//
//  Created by Clint Shank on 1/21/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit

enum DescriptorFileTypes {
    case    database
    case    directory
    case    other
}

class FileDescriptor: NSObject {

    var name = ""
    var type : DescriptorFileTypes = .other
    var url  :  URL!
    var path = ""
    
    
    init(_ filename: String, _ relativePath: String, _ fileUrl: URL, _ fileType: DescriptorFileTypes ) {
        name = filename
        path = relativePath
        type = fileType
        url  = fileUrl
    }

    
    func stringForDescriptor() -> String {
        var     descriptorString = ""
        var     typeString       = ""
        
        switch self.type {
        case .database:     typeString = "database"
        case .directory:    typeString = "directory"
        case .other:        typeString = "other"
        }
        
        descriptorString = String( format:  "[ %@ ][ %@ ]", self.name, typeString )
        
        return descriptorString
    }
    
    
}
