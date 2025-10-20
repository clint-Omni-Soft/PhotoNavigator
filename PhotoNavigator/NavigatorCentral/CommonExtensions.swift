//
//  CommonExtensions.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 04/21/24.
//  Copyright © 2024 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import CoreData



// MARK: CloudCentralDelegate Methods (Public)

extension NavigatorCentral: CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud: Bool ) {
       logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
       
       if stayOffline {
           logTrace( "Stay Offline!" )
       }
       else if canSeeCloud {
           cloudCentral.startSession( self )
           
           notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.connectingToExternalDevice ), object: self )
       }
       else {
           deviceAccessControl.initWith(ownerName: "Unknown", locked: true, byMe: false, updating: false)
           logVerbose( "%@", deviceAccessControl.descriptor() )
           
           notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: self )
       }
       
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles: Int, lastUpdatedBy: String ) {
       logVerbose( "[ %@ ]", descriptionForCompare( didCompareLastUpdatedFiles ) )
       
        externalDeviceLastUpdatedBy = lastUpdatedBy
        
       if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.deviceIsNewer {
           if deviceAccessControl.locked && deviceAccessControl.byMe {
               deviceAccessControl.updating = true
               notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
               
               cloudCentral.copyDatabaseFromDeviceToCloud( self )
           }
           
       }
//       else if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.cloudIsNewer {
//           logTrace( "Verify that we can access all the database files before we start the tranfer" )
//           missingDbFiles = []
//           
//           cloudCentral.fetchDbFiles( self )
//       }
       else {  // This tells the ReceivingVC to reload the barButtonItems and table data
           notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
       }

    }


    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromCloudToDevice: Bool) {
       logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromCloudToDevice ) )
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromDeviceToCloud: Bool) {
       logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromDeviceToCloud ) )
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice: Bool ) {
       logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromCloudToDevice ) )
        deviceAccessControl.updating = false

        cloudCentral.unlockCloud( self )

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )

       if didCopyDatabaseFromCloudToDevice && !openInProgress {
           let     appDelegate = UIApplication.shared.delegate as! AppDelegate
           
           logTrace( "opening database" )
           openDatabaseWith( delegate != nil ? delegate! : appDelegate )
       }
       
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud: Bool ) {
       logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToCloud ) )
       
       if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
           cloudCentral.unlockCloud( self )
       }

        deviceAccessControl.updating = false
 
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didDeleteImage: Bool) {
       logVerbose( "[ %@ ]", stringFor( didDeleteImage ) )
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession: Bool ) {
       logVerbose( "[ %@ ]", stringFor( didEndSession ) )

       if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
           UIApplication.shared.endBackgroundTask( backgroundTaskID )
           backgroundTaskID = UIBackgroundTaskIdentifier.invalid
       }
       
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didFetch imageNames: [String] ) {
        logTrace()
        delegate?.navigatorCentral( self, didFetch: imageNames )  // Tailored to each implementation
    }

    
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImage: Bool, filename: String, image: UIImage ) {
//        logVerbose( "[ %@ ]  filename[ %@ ]", stringFor( didFetchImage ), filename )

        if didFetchImage {
            let     imageData            = image.pngData()!
            let     picturesDirectoryURL = URL.init( fileURLWithPath: pictureDirectoryPath() )
            let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( filename )
            
//            guard let imageData = image.jpegData( compressionQuality: 1.0 ) ?? image.pngData() else {
//                logVerbose( "ERROR!  Could NOT convert UIImage to Data! [ %@ ]", filename )
//                return
//            }
            
            do {
                try imageData.write( to: pictureFileURL, options: .atomic )
                logVerbose( "Saved image to file named[ %@ ]", filename )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }
            
        }
        
        guard let imageRequest = imageRequestQueue.first else {
            logTrace( "ERROR!  Unable to remove request from front of queue!" )
            return
        }

        let     delegate  = imageRequest.1
        let     imageName = imageRequest.0
        
        imageRequestQueue.remove( at: 0 )
        
        if imageName != filename {
            logVerbose( "ERROR!  Image returned[ %@ ] is not what was requested [ %@ ]", filename, imageName )
        }
        
        DispatchQueue.main.async {
            delegate.navigatorCentral( self, didFetchImage: didFetchImage, filename: filename, image : image )  // Tailored to each implementation

            if self.imageRequestQueue.count == 0 {
                self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
            }

        }
                
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud: Bool ) {
        logVerbose( "didLockCloud[ %@ ] ... %@", stringFor( didLockCloud ), deviceAccessControl.descriptor() )

        if deviceAccessControl.updating {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice ), object: self )
        }
        else if deviceAccessControl.locked && !deviceAccessControl.byMe {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked ), object: self )
        }
        else {
            cloudCentral.compareLastUpdatedFiles( self )
        }

    }


    func cloudCentral(_ cloudCentral: CloudCentral, didSaveImageData: Bool, filename: String) {
        logVerbose( "[ %@ ]", stringFor( didSaveImageData ) )
        self.delegate?.navigatorCentral( self, didSaveImageData: didSaveImageData )  // Tailored to each implementation
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession: Bool ) {
       logVerbose( "[ %@ ]", stringFor( didStartSession ) )
       
       if didStartSession {
           cloudCentral.lockCloud( self )
       }
       else {
           notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.unableToConnect ), object: self )
       }
       
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud: Bool) {
       logVerbose( "[ %@ ]", stringFor( didUnlockCloud ) )

       cloudCentral.endSession( self )
    }
       
       
    func cloudCentral(_ cloudCentral: CloudCentral, missingDbFiles: [String] ) {
        logVerbose( "[ %@ ]", missingDbFiles )
        self.missingDbFiles = missingDbFiles
        
        if missingDbFiles.count == 0 {
            didOpenDatabase = false
            deviceAccessControl.updating = true
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )

            cloudCentral.copyDatabaseFromCloudToDevice( self )
        }
        else {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotReadAllDbFiles ), object: self )
        }

    }
        
    
}



// MARK: Data Store Location Methods (Public)

extension NavigatorCentral {
    
    func createLastUpdatedFile() {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     fileUrl   = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
            let     formatter = DateFormatter()
            
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let     dateString   = formatter.string( from: Date() )
            let     outputString = dateString + GlobalConstants.separatorForLastUpdatedString + deviceName
            let     data         = outputString.data( using: .utf8 )
            
            if !fileManager.createFile( atPath: fileUrl.path, contents: data, attributes: nil ) {
                logTrace( "ERROR!  Create failed!" )
            }
            
        }
        else {
            logTrace( "ERROR!  Unable to unwrap documentDirectoryURL" )
        }
        
    }
    

    func dataLocationFor(_ locationString: String ) -> DataLocation {
        var     location: DataLocation = .notAssigned
        
        switch locationString {
        case DataLocationName.device:      location = .device
        case DataLocationName.nas:         location = .nas
        case DataLocationName.shareNas:    location = .shareNas
        default:                           location = .notAssigned
        }
        
        return location
    }
    
    
    func nameForDataLocation(_ location: DataLocation ) -> String {
        var     name = ""
        
        switch location {
        case .device:       name = DataLocationName.device
        case .nas:          name = DataLocationName.nas
        case .shareNas:     name = DataLocationName.shareNas
        default:            name = DataLocationName.notAssigned
        }
        
        return name
    }
    
    
}



// MARK: Image Convenience Methods (Public)

extension NavigatorCentral {
    
    func deleteImageNamed(_ name: String ) -> Bool {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        var         result        = false
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            if !fileManager.fileExists( atPath: imageFileURL.path ) {
                logTrace( "Image does NOT exist!" )
                result = true
            }
            else {
                do {
                    try fileManager.removeItem( at: imageFileURL )
                    
                    logVerbose( "deleted image named [ %@ ]", name )
                    result = true
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to delete image named [ %@ ] ... Error[ %@ ]", name, error.localizedDescription )
                }
                
            }
            
        }
        
        if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
            if stayOffline {
                logTrace( "stayOffline!  queue request" )
                createImageRequestFor( OfflineImageRequestCommands.delete, filename: name )
            }
            else {
                logTrace( "Deleting from NAS" )
                nasCentral.deleteImage( name, self )
            }

        }
        
        return result
    }
    
    
    func downloadFromRemote(_ imageName: String, _ delegate: NavigatorCentralDelegate ) {  // Tailored to each implementation
        logVerbose( "Requesting [ %@ ] from NAS ...", imageName )
        imageRequestQueue.append( (imageName, delegate ) )
        nasCentral.fetchImage( imageName, self )
    }

    
    func extractThumbnailFrom(_ imageName: String, _ description: String ) -> (Bool, UIImage) {
        let picturesDirectoryPath = pictureDirectoryPath()
        var result                = ( false, UIImage.init() )

        if picturesDirectoryPath.isEmpty {
            logVerbose( "ERROR!  pictureDirectoryPath isEmpty!  [ %@ ][ %@ ]", imageName, description )
            return result
        }

        let picturesDirectoryURL = URL.init( fileURLWithPath: picturesDirectoryPath )
        let imageFileURL         = picturesDirectoryURL.appendingPathComponent( imageName )
        
        if !fileManager.fileExists( atPath: imageFileURL.path ) {
            logVerbose( "ERROR!  Image [ %@ ] for [ %@ ] does NOT exist!", imageName, description )
            return result
        }

        guard let imageSource = CGImageSourceCreateWithURL( imageFileURL as CFURL, nil ) else {
            logVerbose( "ERROR!  Could NOT create imageSource for [ %@ ][ %@ ]", imageName, description )
            return result
        }
        
        let thumbnailOptions: [String: Any] = [ kCGImageSourceCreateThumbnailWithTransform     as String: true,
                                                kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
                                                kCGImageSourceThumbnailMaxPixelSize            as String: 512 ]
     
        if let cgImage = CGImageSourceCreateThumbnailAtIndex( imageSource, 0, thumbnailOptions as CFDictionary ) {
//          logVerbose( "Created thumbnail[ %d, %d ] for [ %@ ][ %@ ]", cgImage.width, cgImage.height, imageName, description )
            result = ( true, UIImage( cgImage: cgImage ) )
        }
        else {
            logVerbose( "ERROR!  Could NOT create thumbnail for[ %@ ][ %@ ]! ... [ %d ] imagesPresent", imageName, description, CGImageSourceGetCount( imageSource ) )
        }

        return result
    }

    
    func fetchFromDiskImageFileNamed(_ name: String ) -> (Bool, Data) {
        let directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            if fileManager.fileExists( atPath: imageFileURL.path ) {
                let     imageFileData = fileManager.contents( atPath: imageFileURL.path )
                
                if let imageData = imageFileData {
                    return ( true, imageData )
                }

                logVerbose( "ERROR!  Failed to unwrap data from \n    [ %@ ]", imageFileURL.path )
            }
            else {
                logVerbose( "ERROR!  File NOT found! \n    [ %@ ]", imageFileURL.path )
            }
            
        }
        else {
            logVerbose( "ERROR!  directoryPath is Empty!" )
        }

        return ( false, Data.init() )
    }
    
    
    func fetchImageNamesFromRemote(_ delegate: NavigatorCentralDelegate ) {  // Tailored to each implementation
        logTrace()
        self.delegate = delegate
        
        if !stayOffline {
            nasCentral.fetchImageNames( self )
        }
        
    }
    
    
    func fetchMissingDeviceImages(_ imageName: String, _ descriptor: String,  _ delegate: NavigatorCentralDelegate ) -> Int {   // Tailored to each implementation
        var     imagesRequested = 0
        
        if !imageExistsWith( imageName ) {
            imagesRequested += 1
            
            logVerbose( "Image for [ %@ ] not on disk!  \n    Requesting [ %@ ] from NAS ...", descriptor, imageName )
            imageRequestQueue.append( (imageName, delegate ) )
            nasCentral.fetchImage( imageName, self )
        }
        
        return imagesRequested
    }
        

    func imageExistsWith(_ name: String ) -> Bool {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            return fileManager.fileExists( atPath: imageFileURL.path )
        }
            
        return false
    }
    
    
    func imageNamed(_ name: String, descriptor: String, _ delegate: NavigatorCentralDelegate ) -> (Bool, UIImage) {  // Tailored to each implementation
//        logTrace()
        let result      = fetchFromDiskImageNamed( name )
        let imageLoaded = result.0
        
        if imageLoaded {
            return result
        }
        
        if !stayOffline {
            logVerbose( "Image for [ %@ ] not on disk!  Requesting from NAS [ %@ ]", descriptor, name )
            imageRequestQueue.append( (name, delegate) )
            nasCentral.fetchImage( name, self )
        }
        
        return ( false, UIImage.init() )
    }
    
    
/*
    
   TODO: Reserve this space for WineStock methods that we don't need but we want the rest of the code to show up on matching line numbers
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    
    
    

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 */
 
    
    func saveImage(_ image: UIImage, imageFilename: String, compressed: Bool ) -> Bool {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if directoryPath.isEmpty {
            logTrace( "ERROR!!!  directoryPath.isEmpty!" )
            return false
        }
        
        let     normalizedImage      = normalize( image )
        let     compressionQuality   : CGFloat = ( compressed ? 0.25 : 1.0 )
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( imageFilename )
        
        guard let imageData = normalizedImage.jpegData( compressionQuality: compressionQuality ) else {
            logTrace( "ERROR!  Could NOT convert UIImage to Data!" )
            return false
        }
        
        do {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            logVerbose( "saved compressed[ %@ ] image to [ %@ ]", stringFor( compressed ), imageFilename )
            
            if stayOffline {
                createImageRequestFor( OfflineImageRequestCommands.save, filename: imageFilename )
            }
            else {
                nasCentral.saveImageData( imageData, filename: imageFilename, self )
            }
            
            return true
        }
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", imageFilename, error.localizedDescription )
        }
        
        return false
    }
 
    
    func uploadImageNamed(_ imageName: String, _ delegate: NavigatorCentralDelegate ) {  // Tailored to each implementation
        let     directoryPath        = pictureDirectoryPath()
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( imageName )
        
        if fileManager.fileExists( atPath: imageFileURL.path ) {
            let     imageFileData = fileManager.contents( atPath: imageFileURL.path )
            
            if let imageData = imageFileData {
                logVerbose( "[ %@ ]", imageName )
                self.delegate = delegate

                nasCentral.saveImageData( imageData, filename: imageName, self )
            }
            else {
                logVerbose( "ERROR!  Failed to load data for image for [ %@ ]", imageName )
                delegate.navigatorCentral( self, didSaveImageData: false )  // Tailored to each implementation
            }

        }
        else {
            logVerbose( "ERROR!  [ %@ ] does NOT exist!", imageName )
            delegate.navigatorCentral( self, didSaveImageData: false )  // Tailored to each implementation
        }

    }
    
    
    func verifyImages() {
        logTrace()
        let directoryPath = pictureDirectoryPath()
        
        if directoryPath.isEmpty {
            logVerbose( "ERROR!  directoryPath is Empty!  [ %@ ]", directoryPath )
        }
        else {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            
            logVerbose( "Retrieving contents of [ %@ ]", picturesDirectoryURL.path )
            
            do {
                let filenameArray = try fileManager.contentsOfDirectory(atPath: picturesDirectoryURL.path )
                let filesFound    = filenameArray.count
                var filesLoaded   = 0
                
                logVerbose( "Found [ %d ] image files", filesFound )
                
                for filename in filenameArray {
                    let result = fetchFromDiskImageNamed( filename )
                    
                    logVerbose( "We %@ image data from [ %@ ]", (result.0 ? "loaded" : "FAILED to load" ), filename )
                    
                    if result.0 {
                        filesLoaded += 1
                    }
                    
                }
                
                logVerbose( "Loaded [ %d ] out of [ %d ] image files", filesFound, filesLoaded )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to retrieve contents of [ %@ ] ... Error[ %@ ]", picturesDirectoryURL.path, error.localizedDescription )
            }
            
        }

    }
 
    
    
    // MARK: Image Convenience Utility Methods (Private)

    private func createImageRequestFor(_ command: Int, filename: String ) {
//        logVerbose( "Creating ImageRequest[ %@ ][ %@ ] ", nameForImageRequest( command ), filename )
//        self.persistentContainer.viewContext.perform {
//            let     imageRequest = NSEntityDescription.insertNewObject( forEntityName: EntityNames.imageRequest, into: self.managedObjectContext ) as! ImageRequest
//            
//            imageRequest.index    = Int16( self.offlineImageRequestQueue.count )
//            imageRequest.command  = Int16( command )
//            imageRequest.filename = filename
//            
//            self.saveContext()
//            
//            self.updatedOffline = true
//        }
        
    }
    
    
    private func fetchFromDiskImageNamed(_ name: String ) -> (Bool, UIImage) {
        let result = fetchFromDiskImageFileNamed( name )
        
        if result.0 {
            if let image = UIImage.init( data: result.1 ) {
                return ( true, image )
            }
            
            logVerbose( "ERROR!  Failed to un-wrap image for [ %@ ]", name )
        }

        return ( false, UIImage.init() )
    }
    

    private func logOrientationOf(_ image: UIImage ) {
        var  imageOrientation = "Unknown"
        
        switch image.imageOrientation {
        case .down:             imageOrientation = "down"
        case .downMirrored:     imageOrientation = "downMirrored"
        case .left:             imageOrientation = "left"
        case .leftMirrored:     imageOrientation = "leftMirrored"
        case .right:            imageOrientation = "right"
        case .rightMirrored:    imageOrientation = "rightMirrored"
        case .up:               imageOrientation = "up"
        case .upMirrored:       imageOrientation = "upMirrored"
        default: break
        }
        
        logVerbose( "imageOrientation[ %@ ]", imageOrientation )
    }

    
    private func normalize(_ image: UIImage ) -> UIImage {
        var     rotation: Float = 0.0

        switch image.imageOrientation {
        case .down:             rotation = .pi
        case .downMirrored:     rotation = .pi
        case .left:             rotation = -.pi/2
        case .leftMirrored:     rotation = -.pi/2
        case .right:            rotation = .pi/2
        case .rightMirrored:    rotation = .pi/2
        case .up:               rotation = 0.0
        case .upMirrored:       rotation = 0.0
        default: break
        }
        
        if rotation == 0.0 {
            return image
        }

        logOrientationOf( image )
        logVerbose( "rotation[ %f ]", rotation )
        
        let     naturalImage = UIImage( cgImage: (image.cgImage)!, scale: image.scale, orientation: .up )
        let     rotatedImage = naturalImage.rotate( radians: rotation )!
        
        return rotatedImage
    }
    
    
}



// MARK: NASCentralDelegate Methods (Public)

extension NavigatorCentral: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        if stayOffline {
            logVerbose( "[ %@ ]  Stay Offline!", stringFor( canSeeNasDataSourceFolders ) )
            return
        }
        
        // TODO: Fill me in!
        
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        
        if canSeeNasDataSourceFolders {
            
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        if stayOffline {
            logVerbose( "[ %@ ]  Stay Offline!", stringFor( canSeeNasFolders ) )
            return
        }
        
        if nasCentral.queueIsEmpty() {
            logVerbose( "[ %@ ]  Queue is empty!  Ignoring response", stringFor( canSeeNasFolders ) )
            return
        }
        
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )

        if canSeeNasFolders {
            if nasCentral.currentCommandIsStartSession() {
                logTrace( "Supressing duplicate StartSession command" )
            }
            else {
                nasCentral.startSession( self )
                
                notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.connectingToExternalDevice ), object: self )
            }
            
        }
        else {
            deviceAccessControl.initWith(ownerName: "Unknown", locked: true, byMe: false, updating: false )
            logVerbose( "%@", deviceAccessControl.descriptor() )
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didCompareLastUpdatedFiles: Int, lastUpdatedBy: String ) {
        logVerbose( "[ %@ ] by [ %@ ]", descriptionForCompare( didCompareLastUpdatedFiles ), lastUpdatedBy )
        
        externalDeviceLastUpdatedBy = lastUpdatedBy
        sessionActive               = true

        if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.deviceIsNewer {
            if deviceAccessControl.locked && deviceAccessControl.byMe {
                deviceAccessControl.updating = true
                notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
                
                nasCentral.copyDatabaseFromDeviceToNas( self )
            }
            
        }
        else if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.nasIsNewer {
            logTrace( "Verify that we can access all the database files before we start the transfer" )
            missingDbFiles = []
            
            nasCentral.fetchDbFiles( self )
        }
        else {  // Must be same!
            
            if pleaseWaiting {
                // Tell the PleaseWaitVC that we are done
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                    self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
                }

            }
            
        }

    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromDeviceToNas: Bool ) {
        logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromDeviceToNas ) )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromNasToDevice: Bool ) {
        logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromNasToDevice ) )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromDeviceToNas: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToNas ) )
        
        if updatedOffline {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0 ) {
//                self.persistentContainer.viewContext.perform {
//                    self.processNextOfflineImageRequest()
//                }
//
//            }
           
        }

        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            nasCentral.unlockNas( self )
        }

        deviceAccessControl.updating = false
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromNasToDevice: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromNasToDevice ) )
        
        deviceAccessControl.updating = false

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )

        if didCopyDatabaseFromNasToDevice && !openInProgress && !pleaseWaiting {
            let     appDelegate = UIApplication.shared.delegate as! AppDelegate

            logTrace( "opening database" )
            openDatabaseWith( delegate != nil ? delegate! : appDelegate )
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didDeleteImage: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didDeleteImage ) )
//        if updatedOffline {
//            persistentContainer.viewContext.perform {
//                self.processNextOfflineImageRequest()
//            }
//            
//        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didEndSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didEndSession ) )
        sessionActive = false

        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask( backgroundTaskID )
            backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        
        if !resigningActive {
            logTrace( "re-establishing session" )
            nasCentral.startSession( self )
        }
        
    }
        
    
    func nasCentral(_ nasCentral: NASCentral, didFetch imageNames: [String] ) {
        logTrace()
        DispatchQueue.main.async {
            self.delegate?.navigatorCentral( self, didFetch: imageNames )     // Tailored to each implementation
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didFetchImage: Bool, image: UIImage, filename: String ) {
        logVerbose( "[ %@ ]  filename[ %@ ]", stringFor( didFetchImage ), filename )
        
        if didFetchImage {
            let     imageData            = image.pngData()!
            let     picturesDirectoryURL = URL.init( fileURLWithPath: pictureDirectoryPath() )
            let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( filename )
            
            do {
                try imageData.write( to: pictureFileURL, options: .atomic )
                logVerbose( "Saved [ %d ] bytes to [ %@ ]", imageData.count, pictureFileURL.path )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }
            
        }

        let     imageRequest = imageRequestQueue.first
        let     delegate     = imageRequest!.1
        let     imageName    = imageRequest!.0
        
        imageRequestQueue.removeFirst()
        
        if didFetchImage && imageName != filename {
            logVerbose( "ERROR!  Image returned[ %@ ] is not what was requested [ %@ ]", filename, imageName )
        }

        if self.imageRequestQueue.count == 0 {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        
        if self.updatedOffline {
//            self.persistentContainer.viewContext.perform {
//                self.processNextOfflineImageRequest()
//            }
//            
        }
        else {
            DispatchQueue.main.async {
                delegate.navigatorCentral( self, didFetchImage: didFetchImage, filename: filename, image : image )       // Tailored to each implementation

                if self.imageRequestQueue.count == 0 {
                    self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
                }
                
            }

        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didLockNas: Bool ) {
        logVerbose( "didLockNas[ %@ ]", stringFor( didLockNas ) )

        if deviceAccessControl.updating {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice ), object: self )
        }
        else if deviceAccessControl.locked && !deviceAccessControl.byMe {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked ), object: self )
            sessionActive = true
        }
        else {
            nasCentral.compareLastUpdatedFiles( self )
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didSaveImageData: Bool, filename: String ) {
        logVerbose( "[ %@ ][ %@ ]", stringFor( didSaveImageData ), filename )
        
        if updatedOffline {
//            persistentContainer.viewContext.perform {
//                self.processNextOfflineImageRequest()
//            }
            
        }
        else {
            delegate?.navigatorCentral( self, didSaveImageData: didSaveImageData )  // Tailored to each implementation
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if didStartSession {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                nasCentral.lockNas( self )
            }
            
        }
        else {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.unableToConnect ), object: self )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didUnlockNas: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didUnlockNas ) )
        
        nasCentral.endSession( self )
    }
        

    func nasCentral(_ nasCentral: NASCentral, missingDbFiles: [String] ) {
        logVerbose( "[ %@ ]", missingDbFiles )
        self.missingDbFiles = missingDbFiles
        
        if missingDbFiles.count == 0 {
            didOpenDatabase = false
            deviceAccessControl.updating = true
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )

            nasCentral.copyDatabaseFromNasToDevice( self )
        }
        else {
            if externalDeviceLastUpdatedBy == nasCentral.lastUpdatedUnknown {
                // TODO: The lastUpdated file was either not found or we were unable to read it ... what next?
                logTrace( "We are missing db files and the lastUpdated file was either not found or we were unable to read it" )
            }
            else if externalDeviceLastUpdatedBy == deviceName {
                // TODO: We are missing db files and we were the last one to update it... what next?
                logTrace( "We are missing db files and we were the last one to update it" )
            }
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotReadAllDbFiles ), object: self )
        }

    }
        
    
}



// MARK: UserDefaults Methods (Public)

// The reason these are here is that we can't see the UIKitExtensions in WineStockCentral

extension NavigatorCentral {
    
    func getStringFromUserDefaults(_ key: String ) -> String {
        var savedString = ""
        
        if let string = userDefaults.string( forKey: key ) {
            savedString = string
        }

        return savedString
    }
    
    
    func flagIsPresentInUserDefaults(_ key: String ) -> Bool {
        var     flagIsPresent = false
        
        if let _ = userDefaults.string( forKey: key ) {
            flagIsPresent = true
        }
        
        return flagIsPresent
    }
    
    
    func removeFlagFromUserDefaults(_ key: String ) {
        userDefaults.removeObject(forKey: key )
        
        userDefaults.synchronize()
    }
    
    
    func saveToUserDefaults(_ value: String, for key: String ) {
        userDefaults.removeObject( forKey: key )
        userDefaults.set( value,   forKey: key )
        
        userDefaults.synchronize()
    }
    
    
    func setFlagInUserDefaults(_ key: String ) {
        userDefaults.set( key, forKey: key )
        
        userDefaults.synchronize()
    }
    

}


