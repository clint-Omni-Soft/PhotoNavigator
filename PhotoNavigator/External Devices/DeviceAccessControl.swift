//
//  DeviceAccessControl.swift
//  WineStock
//
//  Ported from WineStock by Clint Shank on 10/10/23.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class DeviceAccessControl: NSObject {

    var byMe      = false
    var locked    = false
    var ownerName = ""
    var updating  = false
    
    static let sharedInstance = DeviceAccessControl()
    

    
    // MARK: Public Methods
    
    func descriptor() -> String {
        return String( format: "DeviceAccessControl: owner[ %@ ] locked[ %@ ] byMe[ %@ ] updating[ %@ ]", ownerName, stringFor( locked ), stringFor( byMe ), stringFor( updating ) )
    }
    
    
    func initForDevice() {
        self.ownerName = UIDevice.current.name
        self.locked    = true
        self.byMe      = true
        self.updating  = false
    }
    
    
    func initWith( ownerName: String, locked: Bool, byMe: Bool, updating: Bool ) {
        self.ownerName = ownerName
        self.locked    = locked
        self.byMe      = byMe
        self.updating  = updating
    }
    
    
    func reset() {
        byMe      = false
        locked    = false
        ownerName = ""
        updating  = false
    }

    
}
