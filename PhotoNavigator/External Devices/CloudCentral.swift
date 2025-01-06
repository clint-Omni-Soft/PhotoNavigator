//
//  CloudCentral.swift
//  WineStock
//
//  Created by Clint Shank on 3/24/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol CloudCentralDelegate: AnyObject {
    
    // Discovery Methods
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud           : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCreateDirectoryTree: Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool )

    // Session Methods
    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles       : Int, lastUpdatedBy: String )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromCloudToDevice: Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromDeviceToCloud: Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didDeleteImage  : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession   : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetch imageNames: [String] )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchFile    : Bool, _ data: Data )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImage   : Bool, filename: String, image: UIImage )
    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud    : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didSaveImageData: Bool, filename: String )
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud  : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, missingDbFiles  : [String] )
}

// Now we supply we provide a default implementation which makes them all optional
extension CloudCentralDelegate {
    
    // Discovery Methods
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud           : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCreateDirectoryTree: Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool ) {}

    // Session Methods
    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles       : Int, lastUpdatedBy: String ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromCloudToDevice: Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromDeviceToCloud: Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didDeleteImage  : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession   : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetch imageNames: [String] ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchFile    : Bool, _ data: Data ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImage   : Bool, filename: String, image: UIImage ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud    : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didSaveImageData: Bool, filename: String ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud  : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, missingDbFiles  : [String] ) {}
}



class CloudCentral: NSObject {
    
    // MARK: Private Variables & Definitions
    
    private enum Command {
        // Discovery Methods
        case CanSeeCloud
        case CreateDrirectoryTree
        case IsRootDirectoryPresent
        
        // Session Methods
        case CompareLastUpdatedFiles
        case CopyAllImagesFromCloudToDevice
        case CopyAllImagesFromDeviceToCloud
        case CopyDatabaseFromCloudToDevice
        case CopyDatabaseFromDeviceToCloud
        case DeleteImage
        case EndSession
        case FetchDbFiles
        case FetchFileOn
        case FetchImage
        case FetchImageNames
        case LockCloud
        case SaveImageData
        case StartSession
        case UnlockCloud
    }
    
    private struct Constants {  // NOTE: lastUpdated needs to be first (which is processed last) to prevent trashing the database in the event that the update fails
        static let databaseFilenameArray = [ Filenames.lastUpdated, Filenames.database, Filenames.databaseShm, Filenames.databaseWal ]
    }
    
    private var cloudDefaultUrl: URL {
        get {
            return FileManager.default.url( forUbiquityContainerIdentifier: nil )!
        }
        
    }
    
    private var cloudPicturesUrl: URL {
        get {
            return cloudRootUrl.appendingPathComponent( DirectoryNames.pictures )
        }
        
    }
    
    private var cloudRootUrl: URL {
        get {
            return cloudDefaultUrl.appendingPathComponent( DirectoryNames.root )
        }
        
    }
    
    private var deviceName: String {
        get {
            var     name = UIDevice.current.name

            if let deviceNameString = UserDefaults.standard.string( forKey: UserDefaultKeys.deviceName ) {
                if !deviceNameString.isEmpty && deviceNameString.count > 0 {
                    name = deviceNameString
                }

            }
            
            return name
        }
        
    }
    
    private var cloudImageFileArray    : [String] = []
    private var currentCommand         : Command!
    private var currentFilename         = ""
    private var delegate               : CloudCentralDelegate!
    private var deviceAccessControl     = DeviceAccessControl.sharedInstance
    private var documentDirectoryURL   : URL!
    private var fileManager             = FileManager.default
    private var fileUrlArray            = [URL].init()
    private var filesToDeleteUrlArray   = [URL].init()
    private var reEstablishConnection   = false
    private var requestQueue           : [[Any]] = []
    private var sessionActive           = false


    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = CloudCentral()        // Prevents anyone else from creating an instance
}



// MARK: External Interface Methods (Queued)

extension CloudCentral {
    
    // Discovery Methods
    func canSeeCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CanSeeCloud, delegate] )
    }
    
    
    func createDrirectoryTree(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CreateDrirectoryTree, delegate] )
    }

    
    func isRootDirectoryPresent(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.IsRootDirectoryPresent, delegate] )
    }


    // Session Methods
    func compareLastUpdatedFiles(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CompareLastUpdatedFiles, delegate] )
    }

    
    func copyAllImagesFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyAllImagesFromCloudToDevice, delegate] )
    }
    
    
    func copyAllImagesFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyAllImagesFromDeviceToCloud, delegate] )
    }
    
    
    func copyDatabaseFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromCloudToDevice, delegate] )
    }
    
    
    func copyDatabaseFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromDeviceToCloud, delegate] )
    }
    
    
    func deleteImage(_ filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.DeleteImage, filename, delegate] )
    }
    
    
    func endSession(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.EndSession, delegate] )
    }
    
    
    func fetchDbFiles(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchDbFiles, delegate] )
    }
    
    
    func fetchFileOn(_ filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchFileOn, filename, delegate] )
    }
    
    
    func fetchImage(_ filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchImage, filename, delegate] )
    }
    
    
    func fetchImageNames(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchImageNames, delegate] )
    }

    
    func lockCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.LockCloud, delegate] )
    }
    
    
    func saveImageData(_ imageData: Data, filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.SaveImageData, imageData, filename, delegate] )
    }
    
    
    func startSession(_ delegate: CloudCentralDelegate  ) {
        addRequest( [Command.StartSession, delegate] )
    }

    
    func unlockCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.UnlockCloud, delegate] )
    }

    
    
    // MARK: Utility Methods (Private)
    
    private func addRequest(_ request: [Any] ) {
        let     requestQueueIdle = requestQueue.isEmpty
        
        logVerbose( "[ %@ ] ... queued requests[ %d ]", stringForCommand( request[0] as! Command ), requestQueue.count )
        requestQueue.append( request )
        
        if requestQueueIdle {
            DispatchQueue.global().async {
                self.processNextRequest( false )
            }
            
        }

    }
    
    
    private func isSessionCommand(_ command: Command ) -> Bool {
        var isSession = true
        
        switch command {
        case .CanSeeCloud, .CreateDrirectoryTree, .FetchFileOn, .IsRootDirectoryPresent:
             isSession = false
        default:    break
        }
        
        return isSession
    }
    
    
    private func processNextRequest(_ popHeadOfQueue: Bool = true ) {

        if popHeadOfQueue {
            logTrace( "Popping head of requestQueue" )
            requestQueue.remove( at: 0 )
        }

        if requestQueue.isEmpty {
            logTrace( "going IDLE" )
            return
        }
        
        guard let request = requestQueue.first else {
            logTrace( "ERROR!  Unable to remove request from front of queue!" )
            return
        }

        let command = request[0] as! Command
        
        if !sessionActive && isSessionCommand( command ) && command != .StartSession {
            logTrace( "Re-establishing session" )
            reEstablishConnection = true
            _startSession( delegate )
            return
        }
        
        logVerbose( "[ %@ ]", stringForCommand( command ) )
        currentCommand = command
        
        switch currentCommand {
            
            // Discovery Methods
        case .CanSeeCloud:                      _canSeeCloud(            request[1] as! CloudCentralDelegate )
        case .CreateDrirectoryTree:             _createDrirectoryTree(   request[1] as! CloudCentralDelegate )
        case .IsRootDirectoryPresent:           _isRootDirectoryPresent( request[1] as! CloudCentralDelegate )
            
            // Session Methods
        case .CompareLastUpdatedFiles:          _compareLastUpdatedFiles(        request[1] as! CloudCentralDelegate )
        case .CopyAllImagesFromCloudToDevice:   _copyAllImagesFromCloudToDevice( request[1] as! CloudCentralDelegate )
        case .CopyAllImagesFromDeviceToCloud:   _copyAllImagesFromDeviceToCloud( request[1] as! CloudCentralDelegate )
        case .CopyDatabaseFromCloudToDevice:    _copyDatabaseFromCloudToDevice(  request[1] as! CloudCentralDelegate )
        case .CopyDatabaseFromDeviceToCloud:    _copyDatabaseFromDeviceToCloud(  request[1] as! CloudCentralDelegate )
        case .DeleteImage:                      _deleteImage(     request[1] as! String, request[2] as! CloudCentralDelegate )
        case .EndSession:                       _endSession(      request[1] as! CloudCentralDelegate )
        case .FetchDbFiles:                     _fetchDbFiles(    request[1] as! CloudCentralDelegate )
        case .FetchFileOn:                      _fetchFileOn(     request[1] as! String, request[2] as! CloudCentralDelegate )
        case .FetchImage:                       _fetchImage(      request[1] as! String, request[2] as! CloudCentralDelegate )
        case .FetchImageNames:                  _fetchImageNames( request[1] as! CloudCentralDelegate )
        case .LockCloud:                        _lockCloud(       request[1] as! CloudCentralDelegate )
        case .SaveImageData:                    _saveImageData(   request[1] as! Data, filename: request[2] as! String, request[3] as! CloudCentralDelegate )
        case .StartSession:                     _startSession(    request[1] as! CloudCentralDelegate )
        case .UnlockCloud:                      _unlockCloud(     request[1] as! CloudCentralDelegate )
            
        default:                               logTrace( "SBH!" )
        }
        
    }
    
    
    private func stringForCommand(_ command: Command ) -> String {
        var     description = "Unknown"
        
        switch command {
        case .CanSeeCloud:                      description = "CanSeeCloud"
        case .CreateDrirectoryTree:             description = "CreateDrirectoryTree"
        case .CompareLastUpdatedFiles:          description = "CompareLastUpdatedFiles"
        case .CopyAllImagesFromDeviceToCloud:   description = "CopyAllImagesFromDeviceToCloud"
        case .CopyAllImagesFromCloudToDevice:   description = "CopyAllImagesFromCloudToDevice"
        case .CopyDatabaseFromDeviceToCloud:    description = "CopyDatabaseFromDeviceToCloud"
        case .CopyDatabaseFromCloudToDevice:    description = "CopyDatabaseFromCloudToDevice"
        case .DeleteImage:                      description = "DeleteImage"
        case .EndSession:                       description = "EndSession"
        case .FetchDbFiles:                     description = "FetchDbFiles"
        case .FetchFileOn:                      description = "FetchFileOn"
        case .FetchImage:                       description = "FetchImage"
        case .FetchImageNames:                  description = "FetchImageNames"
        case .IsRootDirectoryPresent:           description = "IsRootDirectoryPresent"
        case .LockCloud:                        description = "LockCloud"
        case .SaveImageData:                    description = "SaveImageData"
        case .StartSession:                     description = "StartSession"
        case .UnlockCloud:                      description = "UnlockCloud"
        }
        
        return description
    }
    
    
}



// MARK: Discovery Methods (Private)

extension CloudCentral {
    
    private func _canSeeCloud(_ delegate: CloudCentralDelegate ) {
        let canSeeCloud = ( fileManager.ubiquityIdentityToken != nil )
        
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, canSeeCloud: canSeeCloud )
            self.processNextRequest()
        }

    }
    
    
    private func _createDrirectoryTree(_ delegate: CloudCentralDelegate ) {
        var     didCreateDirectoryTree = false

        if fileManager.fileExists( atPath: cloudRootUrl.path ) {
            logTrace( "[ true ] ... cloudRootUrl already present" )
            didCreateDirectoryTree = true
        }
        else {
            
            do {
                try fileManager.createDirectory( atPath: cloudRootUrl.path, withIntermediateDirectories: true, attributes: nil )
                
                do {
                    try fileManager.createDirectory( atPath: cloudPicturesUrl.path, withIntermediateDirectories: true, attributes: nil )
                    didCreateDirectoryTree = true
                    logTrace( "[ true ] ... directoriesCreated" )
               }
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to create pictures directory ... Error[ %@ ]", error.localizedDescription )
                }

            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to create root directory ... Error[ %@ ]", error.localizedDescription )
            }

        }
            
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCreateDirectoryTree: didCreateDirectoryTree )
            self.processNextRequest()
        }
        
    }

    
    private func _isRootDirectoryPresent(_ delegate: CloudCentralDelegate ) {
        var     rootDirectoryIsPresent = false

        if fileManager.fileExists( atPath: cloudRootUrl.path, isDirectory: nil ) {
            if fileManager.fileExists( atPath: cloudPicturesUrl.path, isDirectory: nil ) {
                rootDirectoryIsPresent = true
            }
            
        }
        
        logVerbose( "[ %@ ]", stringFor( rootDirectoryIsPresent ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, rootDirectoryIsPresent: rootDirectoryIsPresent )
            self.processNextRequest()
        }
        
    }
    
    
}




// MARK: Session Methods

extension CloudCentral {
    
    private func _compareLastUpdatedFiles(_ delegate: CloudCentralDelegate ) {
        let compareResult = compareLastUpdatedFiles()
        
        logVerbose( "[ %@ ] lastUpdatedBy: [ %@ ]", descriptionForCompare( compareResult.0 ), compareResult.1 )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCompareLastUpdatedFiles: compareResult.0, lastUpdatedBy: compareResult.1 )
            self.processNextRequest()
        }
        
    }

    
    private func _copyAllImagesFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        loadCloudImagesIntoFileUrlArray()
        deleteFiles()
        
        let     didCopyAllImagesFromCloudToDevice = copyImagesFromCloudToDevice()
        
        logVerbose( "[ %@ ]", stringFor( didCopyAllImagesFromCloudToDevice ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyAllImagesFromCloudToDevice: didCopyAllImagesFromCloudToDevice )
            self.processNextRequest()
        }
        
    }
    
    
    private func _copyAllImagesFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        loadDeviceImagesIntoFileUrlArray()
        deleteFiles()

        let     didCopyAllImagesFromDeviceToCloud = copyImagesFromDeviceToCloud()
        
        logVerbose( "[ %@ ]", stringFor( didCopyAllImagesFromDeviceToCloud ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyAllImagesFromDeviceToCloud: didCopyAllImagesFromDeviceToCloud )
            self.processNextRequest()
        }
        
    }
    
    
    private func _copyDatabaseFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        loadDatabaseFilesIntoFileUrlArray()
        deleteFiles()
        
        let     didCopyDatabaseFromCloudToDevice = copyDatabaseFromCloudToDevice()
        
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromCloudToDevice ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyDatabaseFromCloudToDevice: didCopyDatabaseFromCloudToDevice )
            self.processNextRequest()
        }
        
    }
    
    
    private func _copyDatabaseFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        loadDatabaseFilesIntoFileUrlArray()
        deleteCloudDatabaseFiles()
        
        let     didCopyDatabaseFromDeviceToCloud = copyDatabaseFromDeviceToCloud()
        
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToCloud ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyDatabaseFromDeviceToCloud: didCopyDatabaseFromDeviceToCloud )
            self.processNextRequest()
        }
        
    }
    
    
    private func _deleteImage(_ filename: String, _ delegate: CloudCentralDelegate ) {
        let     cloudUrl       = cloudRootUrl.appendingPathComponent( DirectoryNames.pictures )
        var     didDeleteImage = false
        let     imageUrl       = cloudUrl.appendingPathComponent( filename )
        
        do {
            if fileManager.fileExists(atPath: imageUrl.path ) {
                try fileManager.removeItem( at: imageUrl )
                logVerbose( "[ %@ ]", cloudUrl.lastPathComponent )
            }
            else {
                logVerbose( "[ %@ ] Does NOT Exist", imageUrl.lastPathComponent )
            }
            
            didDeleteImage = true
        }
        catch let error as NSError {
            logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", imageUrl.lastPathComponent, error.localizedDescription )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didDeleteImage: didDeleteImage )
            self.processNextRequest()
        }
        
    }
    
    
    private func _endSession(_ delegate: CloudCentralDelegate ) {
        logTrace()
        sessionActive = false

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didEndSession: true )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchDbFiles(_ delegate: CloudCentralDelegate ) {
        logTrace()
        let     dbFilenameArray = [Filenames.database, Filenames.databaseShm, Filenames.databaseWal, Filenames.lastUpdated]
        var     missingDbFiles  = [String].init()

        for filename in dbFilenameArray {
            let     dbFileUrl  = cloudRootUrl.appendingPathComponent( filename )
            let     dbFileData = fileManager.contents( atPath: dbFileUrl.path )

            if let _ = dbFileData {
                logVerbose( "Read contents of [ %@ ]!", filename )
            }
            else {
                logVerbose( "ERROR!!!  Could NOT read contents of [ %@ ]!", filename )
                missingDbFiles.append( filename )
            }
            
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, missingDbFiles: missingDbFiles )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchFileOn(_ filename: String, _ delegate: CloudCentralDelegate ) {
        var     didFetchFile  = false
        let     fileUrl       = cloudRootUrl.appendingPathComponent( filename )
        let     fileData      = fileManager.contents( atPath: fileUrl.path )
        var     returnData    = Data.init()

        if let data = fileData {
            didFetchFile = true
            returnData = data
        }
        else {
            logVerbose( "ERROR!  Failed to load data for [ %@ ]", filename )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didFetchFile: didFetchFile, returnData )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchImage(_ filename: String, _ delegate: CloudCentralDelegate ) {
        let     cloudPicturesUrl = cloudRootUrl.appendingPathComponent( DirectoryNames.pictures )
        var     didFetchImage    = false
        var     image            = UIImage.init()
        let     imageFileUrl     = cloudPicturesUrl.appendingPathComponent( filename )
        let     imageFileData    = fileManager.contents( atPath: imageFileUrl.path )

        if let imageData = imageFileData {
            if let imageFromData = UIImage.init( data: imageData ) {
                logVerbose( "Loaded image [ %@ ]", filename )
                
                image         = imageFromData
                didFetchImage = true
            }
            else {
                logVerbose( "ERROR!  Unable to convert data into image for [ %@ ]", filename )
            }

        }
        else {
            logVerbose( "ERROR!  Failed to load data for image! [ %@ ]", filename )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didFetchImage: didFetchImage, filename: filename, image: image )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchImageNames(_ delegate :CloudCentralDelegate ) {
//        logTrace()
        var     filenameArray        = [String].init()
        var     imageNameArray       = [String].init()
        let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
        
        if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
            logVerbose( "Pictures directory does NOT exist!\n    [ %@ ] ", picturesDirectoryURL.path )
            return
        }
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: picturesDirectoryURL.path )
            
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1 )
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Filter out hidden files and the Library folder
                if startingString == "." || filename == "Library" {
                    continue
                }
                
                // Filter out databases and directories
                let     fileUrl      = picturesDirectoryURL.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if fileManager.fileExists( atPath: fileUrl.path, isDirectory: &isaDirectory ) {
                    if !isaDirectory.boolValue {
                        imageNameArray.append( filename )
//                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didFetch: imageNameArray )
            self.processNextRequest()
        }
        
    }
    
    
    private func _lockCloud(_ delegate: CloudCentralDelegate ) {
        logTrace()
        let     lockFileUrl     = cloudRootUrl.appendingPathComponent( Filenames.lockFile )
        let     thisDeviceId    = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     thisDeviceName  = UIDevice.current.name

        deviceAccessControl.reset()
        deviceAccessControl.locked = true

        if !fileManager.fileExists( atPath: lockFileUrl.path, isDirectory: nil ) {
            createLockFile()
        }
        else {
            
            do {
                var     fileData: Data!
                
                try fileData = Data( contentsOf: lockFileUrl )
                
                let     lockMessage  = String( decoding: fileData, as: UTF8.self )
                let     components   = lockMessage.components( separatedBy: "," )
                
                if components.count == 2 {
                    let     lockDeviceId   = components[1]
                    let     lockDeviceName = components[0]
                    let     byMe           = ( thisDeviceName == lockDeviceName ) && ( thisDeviceId == lockDeviceId )

                    deviceAccessControl.byMe      = byMe
                    deviceAccessControl.ownerName = lockDeviceName
                    logVerbose( "From existing lock file ... %@", deviceAccessControl.descriptor() )
                }
                else {
                    logVerbose( "ERROR!  lockMessage NOT properly formatted\n    [ %@ ]", lockMessage )

                    if lockMessage.count == 0 {
                        createLockFile()

                        deviceAccessControl.byMe      = true
                        deviceAccessControl.locked    = true
                        deviceAccessControl.ownerName = thisDeviceName
                        logVerbose( "Overriding ... %@", deviceAccessControl.descriptor() )
                    }
                    
                }

            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to read from lock file ... Error[ %@ ]", error.localizedDescription )
            }

        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didLockCloud: self.deviceAccessControl.byMe )
            self.processNextRequest()
        }
        
    }
    
    
    private func _saveImageData(_ imageData: Data, filename: String, _ delegate: CloudCentralDelegate ) {
        var     didSaveImageData = false
        let     cloudPicturesUrl = cloudRootUrl.appendingPathComponent( DirectoryNames.pictures )
        let     imageFileUrl     = cloudPicturesUrl.appendingPathComponent( filename )
                    
        do {
            try imageData.write( to: imageFileUrl, options: .atomic )
            
            didSaveImageData = true
            logVerbose( "Saved image to file named[ %@ ]", filename )
        }
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to write image data ... Error[ %@ ]", error.localizedDescription )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didSaveImageData: didSaveImageData, filename: filename )
            self.processNextRequest()
        }
        
    }
    
    
    private func _startSession(_ delegate: CloudCentralDelegate ) {
        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            documentDirectoryURL = url
        }
        else {
            logTrace( "ERROR:  Unable to load documentDirectoryURL" )
            documentDirectoryURL = URL( fileURLWithPath: "" )
        }
        
        sessionActive = ( fileManager.ubiquityIdentityToken != nil )
        
        logVerbose( "didStartSession[ %@ ]", stringFor( sessionActive ) )
        
        if reEstablishConnection {
            reEstablishConnection = false
            processNextRequest()
        }
        else {
            DispatchQueue.main.async {
                delegate.cloudCentral( self, didStartSession: self.sessionActive )
                self.processNextRequest()
            }
            
        }
        
    }

    
    private func _unlockCloud(_ delegate: CloudCentralDelegate ) {
        var     didUnlockCloud = false
        let     lockFileUrl    = cloudRootUrl.appendingPathComponent( Filenames.lockFile )

        if !fileManager.fileExists( atPath: lockFileUrl.path, isDirectory: nil ) {
            didUnlockCloud = true
            logTrace( "ERROR!  Lock file does NOT exist!" )
        }
        else {
            
            do {
                try fileManager.removeItem(at: lockFileUrl )

                didUnlockCloud = true
                logTrace( "Lock file removed" )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  [ %@ ]", error.localizedDescription )
            }
            
        }
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didUnlockCloud: didUnlockCloud )
            self.processNextRequest()
        }
        
    }
    
    
    
    // MARK: Session Utility Methods (Private)
    
     private func compareLastUpdatedFiles() -> (Int, String) {
         var     compareResult = LastUpdatedFileCompareResult.fileNotFound
         let     deviceFileUrl = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
         let     formatter     = DateFormatter()
         var     updatedBy     = NSLocalizedString( "Title.Unknown", comment: "Unknown" )

         formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
         
         if fileManager.fileExists( atPath: deviceFileUrl.path ) {
             
             if let deviceFileData = fileManager.contents( atPath: deviceFileUrl.path ) {
                 let     cloudFileUrl     = cloudRootUrl.appendingPathComponent( Filenames.lastUpdated )
                 let     deviceDateString = String( decoding: deviceFileData, as: UTF8.self )
                 let     deviceComponents = deviceDateString.components(separatedBy: GlobalConstants.separatorForLastUpdatedString )
                 let     deviceDate       = formatter.date( from: deviceComponents[0] )

                 if let cloudFileData = fileManager.contents( atPath: cloudFileUrl.path ) {
                     let    cloudDateString = String( decoding: cloudFileData, as: UTF8.self )
                     let    cloudComponents = cloudDateString.components(separatedBy: GlobalConstants.separatorForLastUpdatedString )
                     let    cloudDate       = formatter.date( from: cloudComponents[0] )
                     
                     if let dateOnCloud = cloudDate?.timeIntervalSince1970, let dateOnDevice = deviceDate?.timeIntervalSince1970 {
                         if dateOnCloud < dateOnDevice {
                             compareResult = LastUpdatedFileCompareResult.deviceIsNewer
                         }
                         else if dateOnDevice < dateOnCloud {
                             compareResult = LastUpdatedFileCompareResult.cloudIsNewer
                         }
                         
                         if cloudComponents.count == 2 {
                             updatedBy = cloudComponents[1]
                         }
                         
                     }
                     else {
                         logTrace( "ERROR!  Could NOT unwrap dateOnCloud or dateOnDevice!" )
                     }

                 }
                 else {
                     logTrace( "ERROR!  Could NOT unwrap cloudFileData!" )
                 }

             }
             else {
                 logTrace( "ERROR!  Could NOT unwrap deviceFileData!" )
             }
             
         }
         else {
             logTrace( "LastUpdated file does NOT Exist on Device" )
         }
             
        return (compareResult, updatedBy)
    }
    
    
    private func copyDatabaseFromCloudToDevice() -> Bool {
        var     result = true
        
        for fileUrl in fileUrlArray {
            let     cloudUrl = cloudRootUrl.appendingPathComponent( fileUrl.lastPathComponent )
            
            if let cloudFileData = fileManager.contents( atPath: cloudUrl.path ) {
                
                do {
                    try cloudFileData.write( to: fileUrl, options: .atomic )
                    logVerbose( "[ %@ ]", fileUrl.lastPathComponent )
                }
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
                    result = false
                }
                
            }
            else {
                logVerbose( "ERROR!  Unable to read cloud file [ %@ ] ", cloudUrl.lastPathComponent )
                result = false
            }
            
        }
        
        return result
    }
    
    
    private func copyDatabaseFromDeviceToCloud() -> Bool {
        var     index  = 0
        var     result = true

        for fileUrl in fileUrlArray {
            if let deviceFileData = fileManager.contents( atPath: fileUrl.path ) {
                let     cloudUrl = cloudRootUrl.appendingPathComponent( fileUrl.lastPathComponent )
                
                index += 1

                do {
                    try deviceFileData.write( to: cloudUrl, options: .atomic )
                    logVerbose( "[ %@ ]", cloudUrl.lastPathComponent )
                }
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", cloudUrl.lastPathComponent, error.localizedDescription )
                    result = false
                }

            }
            else {
                logVerbose( "ERROR!  Unable to read device file[ %@ ] ", fileUrl.lastPathComponent )
                result = false
            }

        }
        
      return result
    }
    
    
    private func copyImagesFromCloudToDevice() -> Bool {
        var     result = true
        
        for fileUrl in fileUrlArray {
            let     cloudUrl = cloudPicturesUrl.appendingPathComponent( fileUrl.lastPathComponent )
            
            if let cloudFileData = fileManager.contents( atPath: cloudUrl.path ) {
                
                do {
                    try cloudFileData.write( to: fileUrl, options: .atomic )
                    logVerbose( "[ %@ ]", fileUrl.lastPathComponent )
                }
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
                    result = false
                }
                
            }
            else {
                logVerbose( "ERROR!  Unable to read cloud file [ %@ ] ", cloudUrl.lastPathComponent )
                result = false
            }
            
        }
        
        return result
    }
    
    
    private func copyImagesFromDeviceToCloud() -> Bool {
        var     index  = 0
        var     result = true

        for fileUrl in fileUrlArray {
            if let deviceFileData = fileManager.contents( atPath: fileUrl.path ) {
                let     cloudUrl = cloudPicturesUrl.appendingPathComponent( fileUrl.lastPathComponent )
                
                index += 1

                do {
                    try deviceFileData.write( to: cloudUrl, options: .atomic )
                    logVerbose( "[ %@ ]", cloudUrl.lastPathComponent )
                }
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", cloudUrl.lastPathComponent, error.localizedDescription )
                    result = false
                }

            }
            else {
                logVerbose( "ERROR!  Unable to read device file[ %@ ] ", fileUrl.lastPathComponent )
                result = false
            }

        }
      
        return result
    }
    
    
    private func createLockFile() {
        let     lockFileUrl     = cloudRootUrl.appendingPathComponent( Filenames.lockFile )
        let     thisDeviceId    = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     lockMessage     = String( format: "%@,%@", deviceName, thisDeviceId )
        let     fileData        = Data( lockMessage.utf8 )
        
        do {
            try fileData.write( to: lockFileUrl )
            
            deviceAccessControl.byMe      = true
            deviceAccessControl.ownerName = deviceName
            logVerbose( "Created lock file ... %@", deviceAccessControl.descriptor() )
        }
        catch let error as NSError {
            deviceAccessControl.ownerName = "Unknown"
            logVerbose( "ERROR!!!  Lock file create failed! ... [ %@ ]", error.localizedDescription )
        }

    }
    
    
    private func deleteCloudDatabaseFiles() {
        for url in filesToDeleteUrlArray {
            let     cloudUrl = cloudRootUrl.appendingPathComponent( url.lastPathComponent )
            
            do {
                if fileManager.fileExists(atPath: cloudUrl.path ) {
                    try fileManager.removeItem( at: cloudUrl )
                    logVerbose( "[ %@ ]", cloudUrl.lastPathComponent )
                }
                else {
                    logVerbose( "[ %@ ] Does NOT Exist", cloudUrl.lastPathComponent )
                }
                
            }
            catch let error as NSError {
                logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", cloudUrl.lastPathComponent, error.localizedDescription )
            }

        }

        filesToDeleteUrlArray.removeAll()
    }
    
    
    private func deleteFiles() {
        for fileUrl in filesToDeleteUrlArray {
            
            do {
                if fileManager.fileExists(atPath: fileUrl.path ) {
                    try fileManager.removeItem( at: fileUrl )
                    logVerbose( "[ %@ ]", fileUrl.lastPathComponent )
                }
                else {
                    logVerbose( "[ %@ ] Does NOT Exist", fileUrl.lastPathComponent )
                }
                
            }
            catch let error as NSError {
                logVerbose( "Error: [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
            }
            
        }
        
        filesToDeleteUrlArray.removeAll()
    }
    
    
    private func loadDatabaseFilesIntoFileUrlArray() {
        logTrace()
        fileUrlArray         .removeAll()
        filesToDeleteUrlArray.removeAll()

        for filename in Constants.databaseFilenameArray {
            let     fileUrl = documentDirectoryURL.appendingPathComponent( filename )
            
            fileUrlArray.append( fileUrl )
//            logVerbose( "[ %@ ]", fileUrl.path )
        }
        
        filesToDeleteUrlArray.append( contentsOf: fileUrlArray )
    }
        
        
    private func loadCloudImagesIntoFileUrlArray() {
        fileUrlArray.removeAll()
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory (at: cloudPicturesUrl, includingPropertiesForKeys: nil )
            
            fileUrlArray = fileURLs
        }
        catch {
            logVerbose("ERROR!  Unable to enumerate files [ %@ ][ %@ ]", cloudPicturesUrl.path, error.localizedDescription )
        }

    }
    
    
    private func loadDeviceImagesIntoFileUrlArray() {
        logTrace()
        var     filenameArray        = [String].init()
        let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
        
        fileUrlArray   .removeAll()
        filesToDeleteUrlArray.removeAll()

        if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
            logVerbose( "Pictures directory does NOT exist!\n    [ %@ ] ", picturesDirectoryURL.path )
            return
        }
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: picturesDirectoryURL.path )
            
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1 )
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Filter out hidden files and the Library folder
                if startingString == "." || filename == "Library" {
                    continue
                }
                
                // Filter out databases and directories
                let     fileUrl      = picturesDirectoryURL.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if fileManager.fileExists( atPath: fileUrl.path, isDirectory: &isaDirectory ) {
                    if !isaDirectory.boolValue {
                        fileUrlArray.append( fileUrl )
//                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
            filesToDeleteUrlArray.append( contentsOf: fileUrlArray )
        }
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
    }

        
}



