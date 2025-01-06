//
//  PhotosExtensions.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 10/1/24.
//

import Photos


extension PHAsset {
    
    func creationDateAsTuple() -> (Int, Int, Int) {
        let calendar = Calendar.current
        let year     = calendar.component( .year,  from: creationDate! )
        let month    = calendar.component( .month, from: creationDate! )
        let day      = calendar.component( .day,   from: creationDate! )

        return ( year, month, day )
    }


    func descriptorString() -> String {
        var descriptor = stringForPlaybackStyle()
        
        if self.mediaType == PHAssetMediaType.video {
            descriptor += String( format: " [%.0f sec]", self.duration )
        }
        
        if let creationDate = self.creationDate {
            descriptor += String( format: " created %@", stringFor( creationDate ) )
        }
        
        if let location = self.location {
            descriptor += String( format: "\n @ [ %f, %f ]", location.coordinate.latitude, location.coordinate.longitude )
        }
        
        return descriptor
    }
    
    
    func hasLocation() -> Bool {
        var locationPresent = false
        
        if let _ = self.location {
            locationPresent = true
        }

        return locationPresent
    }
    
    
    func stringForMediaType() -> String {
        var descriptor = ""
        
        switch self.mediaType {
        case .image:            descriptor = "image"
        case .video:            descriptor = "video"
        default:                descriptor = "unsupported"
        }
        
        return descriptor
    }
    
    
    func stringForPlaybackStyle() -> String {
        var descriptor = ""
        
        switch self.playbackStyle {
        case .image:            descriptor = "image"
        case .imageAnimated:    descriptor = "imageAnimated"
        case .livePhoto:        descriptor = "livePhoto"
        case .video:            descriptor = "video"
        case .videoLooping:     descriptor = "videoLooping"
        default:                descriptor = "unsupported"
        }
        
        return descriptor
    }
    
    
}



