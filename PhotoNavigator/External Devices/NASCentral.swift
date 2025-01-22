//
//  NASCentral.swift
//  WineStock
//
//  Created by Clint Shank on 4/10/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol NASCentralDelegate: AnyObject {
    
    // DataSource Methods
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool )
    func nasCentral(_ nasCentral: NASCentral, didSaveDataSourceAccessKey: Bool )
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession : Bool, share: SMBShare )

    // DataStore Access Methods
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders          : Bool )
    func nasCentral(_ nasCentral: NASCentral, didCloseShareAndDevice    : Bool )
    func nasCentral(_ nasCentral: NASCentral, didConnectToDevice        : Bool, _ device        : SMBDevice   )
    func nasCentral(_ nasCentral: NASCentral, didCreateDirectory        : Bool )
    func nasCentral(_ nasCentral: NASCentral, didFetchDevices           : Bool, _ deviceArray   : [SMBDevice] )
    func nasCentral(_ nasCentral: NASCentral, didFetchDirectories       : Bool, _ directoryArray: [SMBFile]   )
    func nasCentral(_ nasCentral: NASCentral, didFetchFile              : Bool, _ data: Data )
    func nasCentral(_ nasCentral: NASCentral, didFetchShares            : Bool, _ shareArray    : [SMBShare]  )
    func nasCentral(_ nasCentral: NASCentral, didSaveDataStoreAccessKey : Bool )
    func nasCentral(_ nasCentral: NASCentral, didSaveData               : Bool )
    
    // DataStore Session Methods
    func nasCentral(_ nasCentral: NASCentral, didCompareLastUpdatedFiles     : Int, lastUpdatedBy: String )
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromDeviceToNas: Bool )
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromNasToDevice: Bool )
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromDeviceToNas : Bool )
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromNasToDevice : Bool )
    func nasCentral(_ nasCentral: NASCentral, didDeleteImage  : Bool )
    func nasCentral(_ nasCentral: NASCentral, didEndSession   : Bool )
    func nasCentral(_ nasCentral: NASCentral, didFetch          imageNames: [String] )
    func nasCentral(_ nasCentral: NASCentral, didFetchImage   : Bool, image: UIImage, filename: String )
    func nasCentral(_ nasCentral: NASCentral, didLockNas      : Bool )
    func nasCentral(_ nasCentral: NASCentral, didSaveImageData: Bool, filename: String )
    func nasCentral(_ nasCentral: NASCentral, didStartSession : Bool )
    func nasCentral(_ nasCentral: NASCentral, didUnlockNas    : Bool )
    func nasCentral(_ nasCentral: NASCentral, missingDbFiles  : [String] )
    
    // These methods do double-duty
    func nasCentral(_ nasCentral: NASCentral, didFetchFiles: Bool, _ fileArray: [SMBFile]   )
    func nasCentral(_ nasCentral: NASCentral, didOpenShare : Bool, _ share    : SMBShare    )
}


// Now we supply we provide a default implementation which makes them all optional
extension NASCentralDelegate {
    
    // DataSource Methods
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didSaveDataSourceAccessKey: Bool ) {}
    
    // DataStore Access Methods
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders          : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didCloseShareAndDevice    : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didConnectToDevice        : Bool, _ device        : SMBDevice   ) {}
    func nasCentral(_ nasCentral: NASCentral, didCreateDirectory        : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didFetchDevices           : Bool, _ deviceArray   : [SMBDevice] ) {}
    func nasCentral(_ nasCentral: NASCentral, didFetchDirectories       : Bool, _ directoryArray: [SMBFile]   ) {}
    func nasCentral(_ nasCentral: NASCentral, didFetchFile              : Bool, _ data: Data ) {}
    func nasCentral(_ nasCentral: NASCentral, didFetchShares            : Bool, _ shareArray    : [SMBShare]  ) {}
    func nasCentral(_ nasCentral: NASCentral, didSaveDataStoreAccessKey : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didSaveData               : Bool ) {}
    
    // DataStore Session Methods
    func nasCentral(_ nasCentral: NASCentral, didCompareLastUpdatedFiles     : Int, lastUpdatedBy: String ) {}
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromDeviceToNas: Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromNasToDevice: Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromDeviceToNas : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromNasToDevice : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didDeleteImage  : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didEndSession   : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didFetch          imageNames: [String] ) {}
    func nasCentral(_ nasCentral: NASCentral, didFetchImage   : Bool, image: UIImage, filename: String ) {}
    func nasCentral(_ nasCentral: NASCentral, didLockNas      : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didSaveImageData: Bool, filename: String ) {}
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession: Bool, share: SMBShare ) {}
    func nasCentral(_ nasCentral: NASCentral, didStartSession : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, didUnlockNas    : Bool ) {}
    func nasCentral(_ nasCentral: NASCentral, missingDbFiles  : [String] ) {}
    
    // These methods do double-duty
    func nasCentral(_ nasCentral: NASCentral, didFetchFiles: Bool, _ fileArray: [SMBFile]   ) {}
    func nasCentral(_ nasCentral: NASCentral, didOpenShare : Bool, _ share    : SMBShare    ) {}
}



class NASCentral: NSObject {

    // MARK: Public Variables
    
    let lastUpdatedUnknown = NSLocalizedString( "Title.Unknown", comment: "Unknown" )
    
    var dataSourceAccessKey: NASDescriptor {
        get {
            var     accessKey = NASDescriptor()
            
            if let descriptorString = UserDefaults.standard.string( forKey: UserDefaultKeys.dataSourceDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    accessKey.host         = components[0]
                    accessKey.netbiosName  = components[1]
                    accessKey.group        = components[2]
                    accessKey.userName     = components[3]
                    accessKey.password     = components[4]
                    accessKey.share        = components[5]
                    accessKey.path         = components[6]
                }

            }
            
            return accessKey
        }
        
        set ( accessKey ) {
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               accessKey.host,      accessKey.netbiosName, accessKey.group,
                                               accessKey.userName,  accessKey.password,
                                               accessKey.share,     accessKey.path )

            UserDefaults.standard.set( descriptorString, forKey: UserDefaultKeys.dataSourceDescriptor )
            UserDefaults.standard.synchronize()
        }
        
    }
    
    var dataStoreAccessKey: NASDescriptor {
        get {
            var     accessKey = NASDescriptor()
            
            if let descriptorString = UserDefaults.standard.string( forKey: UserDefaultKeys.dataStoreDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    accessKey.host         = components[0]
                    accessKey.netbiosName  = components[1]
                    accessKey.group        = components[2]
                    accessKey.userName     = components[3]
                    accessKey.password     = components[4]
                    accessKey.share        = components[5]
                    accessKey.path         = components[6]
                }

            }
            
            return accessKey
        }
        
        set ( accessKey ) {
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               accessKey.host,      accessKey.netbiosName, accessKey.group,
                                               accessKey.userName,  accessKey.password,
                                               accessKey.share,     accessKey.path )

            UserDefaults.standard.set( descriptorString, forKey: UserDefaultKeys.dataStoreDescriptor )
            UserDefaults.standard.synchronize()
        }
        
    }
    
    var returnCsvFiles = false      // Used by Settings/Import from CSV ... we will pass this through to SMBCentral

    
    
    // MARK: Private Variables
    
    private struct Constants {  // NOTE: lastUpdated needs to be first (which is processed last) to prevent trashing the database in the event that the update fails
        static let databaseFilenameArray  = [ Filenames.lastUpdated, Filenames.database, Filenames.databaseShm, Filenames.databaseWal ]
        static let scanTime: TimeInterval = 3
    }
    
    private enum Command {
        
        // DataSource Methods
        case CanSeeNasDataSourceFolders
        case SaveDataSourceAccessKey
        case StartDataSourceSession

       // DataStore Access Methods
        case CanSeeNasFolders
        case CloseShareAndDevice
        case ConnectTo
        case CreateDirectoryOn
        case FetchConnectedDevices
        case FetchDirectoriesFrom
        case FetchFileOn
        case FetchShares
        case SaveDataStoreAccessKey
        case SaveData
        
        // DataStore Session Methods
        case CompareLastUpdatedFiles
        case CopyAllImagesFromDeviceToNas
        case CopyAllImagesFromNasToDevice
        case CopyDatabaseFromDeviceToNas
        case CopyDatabaseFromNasToDevice
        case DeleteImage
        case EndSession
        case FetchDbFiles
        case FetchImage
        case FetchImageNames
        case LockNas
        case SaveImageData
        case StartSession
        case UnlockNas

        // These methods do double-duty
        case FetchFilesAt
        case OpenShare
    }
    
    private var currentCommand          : Command!
    private var currentFilename         = ""
    private var dbDataArray             : [(String, Data)] = []
    private var dbFilenameArray         : [String] = []
    private var delegate                : NASCentralDelegate?
    private let deviceAccessControl     = DeviceAccessControl.sharedInstance
    private var deviceUrlArray          = [URL].init()
    private var deviceUrlArrayIndex     = 0
    private var deviceUrlsToDeleteArray = [URL].init()
    private var discoveryTimer          : Timer?
    private var documentDirectoryURL    : URL!
    private var fileManager             = FileManager.default
    private var missingDbFiles          = [String].init()
    private var nasImageFileArray       : [SMBFile] = []
    private var reEstablishConnection   = false
    private var requestQueue            : [[Any]] = []
    private var selectedDevice          : SMBDevice?
    private var selectedShare           : SMBShare?
    private var sessionActive           = false
    private var smbCentral              = SMBCentral.sharedInstance
    private var workingAccessKey        = NASDescriptor()
    
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
    
    
    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = NASCentral()        // Prevents anyone else from creating an instance
}



// MARK: External Interface Methods (Queued)

extension NASCentral {

    // MARK: DataSource Methods (Public)
    
    func canSeeNasDataSourceFolders(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CanSeeNasDataSourceFolders, delegate] )
    }
    

    func saveDataSourceAccessKey(_ path: String, _ delegate: NASCentralDelegate  ) {
        addRequest( [Command.SaveDataSourceAccessKey, path, delegate] )
    }
    
    
    func startDataSourceSession(_ delegate: NASCentralDelegate  ) {
        addRequest( [Command.StartDataSourceSession, delegate] )
    }

    
    // MARK: DataStore Access Methods (Public)
    
    func canSeeNasFolders(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CanSeeNasFolders, delegate] )
    }
    

    func closeShareAndDevice(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CloseShareAndDevice, delegate] )
    }
    
    
    func connectTo(_ device: SMBDevice, _ userName: String, _ password: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.ConnectTo, device, userName, password, delegate] )
    }
    
    
    func createDirectoryOn(_ share: SMBShare, _ path: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.CreateDirectoryOn, share, path, delegate] )
    }
    
    
    func fetchConnectedDevices(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchConnectedDevices, delegate] )
    }
    
    
    func fetchDirectoriesFrom(_ share: SMBShare, _ atPath: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchDirectoriesFrom, share, atPath, delegate] )
    }
    
    
    func fetchFileOn(_ share: SMBShare, _ fullpath: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchFileOn, share, fullpath, delegate] )
    }
    
    
    func fetchShares(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchShares, delegate] )
    }
    
    
    func saveData(_ data: Data, _ share: SMBShare, _ fullPath: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.SaveData, data, share, fullPath, delegate] )
    }
    
    
    func saveDataStoreAccessKey(_ path: String, _ delegate: NASCentralDelegate  ) {
        addRequest( [Command.SaveDataStoreAccessKey, path, delegate] )
    }
    
    

    // MARK: DataStore Session Methods
    
    func compareLastUpdatedFiles(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CompareLastUpdatedFiles, delegate] )
    }

    
    func copyAllImagesFromDeviceToNas(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CopyAllImagesFromDeviceToNas, delegate] )
    }
    
    
    func copyAllImagesFromNasToDevice(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CopyAllImagesFromNasToDevice, delegate] )
    }
    
    
    func copyDatabaseFromDeviceToNas(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromDeviceToNas, delegate] )
    }
    
    
    func copyDatabaseFromNasToDevice(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromNasToDevice, delegate] )
    }
    
    
    func deleteImage(_ filename: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.DeleteImage, filename, delegate] )
    }
    
    
    func endSession(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.EndSession, delegate] )
    }
    
    
    func fetchDbFiles(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchDbFiles, delegate] )
    }
    

    func fetchImage(_ filename: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchImage, filename, delegate] )
    }
    
    
    func fetchImageNames(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchImageNames, delegate] )
    }

    
    func lockNas(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.LockNas, delegate] )
    }
    
    
    func saveImageData(_ imageData: Data, filename: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.SaveImageData, imageData, filename, delegate] )
    }
    
    
    func startSession(_ delegate: NASCentralDelegate  ) {
        addRequest( [Command.StartSession, delegate] )
    }

    
    func unlockNas(_ delegate: NASCentralDelegate ) {
        addRequest( [Command.UnlockNas, delegate] )
    }


    // MARK: These methods do double-duty

    func fetchFilesAt(_ path: String, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.FetchFilesAt, path, delegate] )
    }
    
    
    func openShare(_ share: SMBShare, _ delegate: NASCentralDelegate ) {
        addRequest( [Command.OpenShare, share, delegate] )
    }
    

    
    // MARK: Utility Methods (Public)
    
    func currentCommandIsStartSession() -> Bool {
        return currentCommand == .StartSession
    }
    

    func emptyQueue() {
        logVerbose( "queue contents[ %@ ]", queueContents() )
        requestQueue.removeAll()
    }


    func queueContents() -> String {
        var queueContents = ""
        
        for request in requestQueue {
            let command = request[0] as! Command
            
            if !queueContents.isEmpty {
                queueContents += ", "
            }
            
            queueContents += stringForCommand( command )
        }
        
        return queueContents
    }
    
    
    func queueIsEmpty() -> Bool {
        return requestQueue.isEmpty
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
            // These are DataSource methods
        case .CanSeeNasDataSourceFolders, .SaveDataSourceAccessKey, .StartDataSourceSession:            isSession = false
            
            // These are DataStore methods
        case .CanSeeNasFolders, .CloseShareAndDevice, .ConnectTo, .CreateDirectoryOn, .FetchConnectedDevices,
             .FetchDirectoriesFrom, .FetchFileOn, .FetchShares, .SaveDataStoreAccessKey, .SaveData:     isSession = false
            
            // These methods do double-duty
        case .FetchFilesAt, .OpenShare:                                                                 isSession = false

        default:    break
        }
        
        return isSession
    }
    
    
    private func processNextRequest(_ popHeadOfQueue: Bool = true ) {
        
        if popHeadOfQueue && !requestQueue.isEmpty {
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
            smbCentral.startSession( dataStoreAccessKey, self )
            return
        }
        
        logVerbose( "[ %@ ]", stringForCommand( command ) )
        currentCommand = command

        switch currentCommand {
            
            // DataSource Methods
        case .CanSeeNasDataSourceFolders:       _canSeeNasDataSourceFolders( request[1] as! NASCentralDelegate )
        case .SaveDataSourceAccessKey:          _saveDataSourceAccessKey(    request[1] as! String, request[2] as! NASCentralDelegate )
        case .StartDataSourceSession:           _startDataSourceSession(     request[1] as! NASCentralDelegate )

            // DataStore Access Methods
        case .CanSeeNasFolders:                 _canSeeNasFolders(       request[1] as! NASCentralDelegate )
        case .CloseShareAndDevice:              _closeShareAndDevice(    request[1] as! NASCentralDelegate )
        case .ConnectTo:                        _connectTo(              request[1] as! SMBDevice, request[2] as! String, request[3] as! String, request[4] as! NASCentralDelegate )
        case .CreateDirectoryOn:                _createDirectoryOn(      request[1] as! SMBShare,  request[2] as! String, request[3] as! NASCentralDelegate )
        case .FetchConnectedDevices:            _fetchConnectedDevices(  request[1] as! NASCentralDelegate )
        case .FetchDirectoriesFrom:             _fetchDirectoriesFrom(   request[1] as! SMBShare,  request[2] as! String, request[3] as! NASCentralDelegate )
        case .FetchFileOn:                      _fetchFileOn(            request[1] as! SMBShare,  request[2] as! String, request[3] as! NASCentralDelegate )
        case .FetchShares:                      _fetchShares(            request[1] as! NASCentralDelegate )
        case .SaveDataStoreAccessKey:           _saveDataStoreAccessKey( request[1] as! String,    request[2] as! NASCentralDelegate )       // This method does double-duty
        case .SaveData:                         _saveData(               request[1] as! Data,      request[2] as! SMBShare, request[3] as! String, request[4] as! NASCentralDelegate )

            // DataStore Session Methods
        case .CompareLastUpdatedFiles:          _compareLastUpdatedFiles(      request[1] as! NASCentralDelegate )
        case .CopyAllImagesFromDeviceToNas:     _copyAllImagesFromDeviceToNas( request[1] as! NASCentralDelegate )
        case .CopyAllImagesFromNasToDevice:     _copyAllImagesFromNasToDevice( request[1] as! NASCentralDelegate )
        case .CopyDatabaseFromDeviceToNas:      _copyDatabaseFromDeviceToNas(  request[1] as! NASCentralDelegate )
        case .CopyDatabaseFromNasToDevice:      _copyDatabaseFromNasToDevice(  request[1] as! NASCentralDelegate )
        case .DeleteImage:                      _deleteImage(                  request[1] as! String, request[2] as! NASCentralDelegate )
        case .EndSession:                       _endSession(                   request[1] as! NASCentralDelegate )
        case .FetchDbFiles:                     _fetchDbFiles(                 request[1] as! NASCentralDelegate )
        case .FetchImage:                       _fetchImage(                   request[1] as! String, request[2] as! NASCentralDelegate )
        case .FetchImageNames:                  _fetchImageNames(              request[1] as! NASCentralDelegate )
        case .LockNas:                          _lockNas(                      request[1] as! NASCentralDelegate )
        case .SaveImageData:                    _saveImageData(                request[1] as! Data, filename: request[2] as! String, request[3] as! NASCentralDelegate )
        case .StartSession:                     _startSession(                 request[1] as! NASCentralDelegate )
        case .UnlockNas:                        _unlockNas(                    request[1] as! NASCentralDelegate )

            // These methods do double-duty
        case .FetchFilesAt:                     _fetchFilesAt( request[1] as! String,   request[2] as! NASCentralDelegate )         // This method does double-duty
        case .OpenShare:                        _openShare(    request[1] as! SMBShare, request[2] as! NASCentralDelegate )

        default:                                logTrace( "SBH!" )
        }
        
    }
    
    
    private func stringForCommand(_ command: Command ) -> String {
        var     description = "Unknown"
        
        switch command {
            
            // DataSouce Methods
        case .CanSeeNasDataSourceFolders:       description = "CanSeeNasDataSourceFolders"
        case .SaveDataSourceAccessKey:          description = "SaveDataSourceAccessKey"
        case .StartDataSourceSession:           description = "StartDataSourceSession"

            // DataStore Access Methods
        case .CanSeeNasFolders:                 description = "CanSeeNasFolders"
        case .CloseShareAndDevice:              description = "CloseShareAndDevice"
        case .CompareLastUpdatedFiles:          description = "CompareLastUpdatedFiles"
        case .ConnectTo:                        description = "ConnectTo"
        case .CreateDirectoryOn:                description = "CreateDirectoryOn"
        case .FetchConnectedDevices:            description = "FetchConnectedDevices"
        case .FetchDirectoriesFrom:             description = "FetchDirectoriesFrom"
        case .FetchFileOn:                      description = "FetchFileOn"
        case .FetchShares:                      description = "FetchShares"
        case .SaveDataStoreAccessKey:           description = "SaveDataStoreAccessKey"
        case .SaveData:                         description = "SaveData"

            // DataStore Session Methods
        case .CopyAllImagesFromDeviceToNas:     description = "CopyAllImagesFromDeviceToNas"
        case .CopyAllImagesFromNasToDevice:     description = "CopyAllImagesFromNasToDevice"
        case .CopyDatabaseFromDeviceToNas:      description = "CopyDatabaseFromDeviceToNas"
        case .CopyDatabaseFromNasToDevice:      description = "CopyDatabaseFromNasToDevice"
        case .DeleteImage:                      description = "DeleteImage"
        case .EndSession:                       description = "EndSession"
        case .FetchDbFiles:                     description = "FetchDbFiles"
        case .FetchImage:                       description = "FetchImage"
        case .FetchImageNames:                  description = "FetchImageNames"
        case .LockNas:                          description = "LockNas"
        case .SaveImageData:                    description = "SaveImageData"
        case .StartSession:                     description = "StartSession"
        case .UnlockNas:                        description = "UnlockNas"

            // These methods do double-duty
        case .FetchFilesAt:                     description = "FetchFilesAt"
        case .OpenShare:                        description = "OpenShare"
        }
        
        return description
    }
    
    
}



// MARK: Access Methods (Private)

extension NASCentral {
    
    // MARK: DataSource Methods
    
    private func _canSeeNasDataSourceFolders(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        smbCentral.findFolderAt( dataSourceAccessKey, self )
    }
    
    
    private func _saveDataSourceAccessKey(_ path: String, _ delegate: NASCentralDelegate ) {
        logVerbose( "[ %@ ]", path )
        workingAccessKey.path = path
        dataSourceAccessKey   = workingAccessKey
        
        DispatchQueue.main.async {
            delegate.nasCentral( self, didSaveDataSourceAccessKey: true )
            self.processNextRequest()
        }
        
    }
    
    
    private func _startDataSourceSession(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            documentDirectoryURL = url
        }
        else {
            logTrace( "ERROR:  Unable to load documentDirectoryURL" )
            documentDirectoryURL = URL( fileURLWithPath: "" )
        }

        smbCentral.startSession( dataSourceAccessKey, self )
    }
    
    
    
    // MARK: DataStore Methods

    private func _canSeeNasFolders(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        smbCentral.findFolderAt( dataStoreAccessKey, self )
    }
    
    
    private func _closeShareAndDevice(_ delegate: NASCentralDelegate ) {
//        logTrace()
        if let share = selectedShare {
            if share.isOpen {
                share.close( {
                    (error) in
                    
                    if error != nil {
                        logVerbose( "ERROR!  [ %@ ]", error?.localizedDescription ?? "Unknown error" )
                    }
                        
                    if let _ = self.selectedDevice {
                        self.smbCentral.disconnect()
                    }
                   
                    DispatchQueue.main.async {
                        delegate.nasCentral( self, didCloseShareAndDevice: true )
                        self.processNextRequest()
                    }

                })

            }

        }
        else {
            if let _ = self.selectedDevice {
                smbCentral.disconnect()
             }
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didCloseShareAndDevice: true )
                self.processNextRequest()
            }
            
        }

        self.selectedShare  = nil
        self.selectedDevice = nil
    }
    
    
    private func _connectTo(_ device: SMBDevice, _ userName: String, _ password: String, _ delegate: NASCentralDelegate ) {
//       logTrace()
       self.delegate = delegate
       selectedDevice = device
       
       workingAccessKey.host        = device.host
       workingAccessKey.netbiosName = device.netbiosName
       workingAccessKey.group       = device.group
       workingAccessKey.password    = password
       workingAccessKey.userName    = userName
       workingAccessKey.share       = ""
       workingAccessKey.path        = ""
       
       smbCentral.connectTo( device, userName, password, self )
    }
       
       
    private func _createDirectoryOn(_ share: SMBShare, _ path: String, _ delegate: NASCentralDelegate ) {
//       logTrace()
       self.delegate = delegate

       smbCentral.createDirectoryOn( share, path, self )
    }
       
    
    private func _fetchConnectedDevices(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        if smbCentral.startDiscoveryWith( self ) {
            DispatchQueue.main.async {
                self.discoveryTimer = Timer.scheduledTimer( timeInterval: Constants.scanTime, target: self, selector: #selector( self.timerFired ), userInfo: nil, repeats: false )
            }
            
        }
        else {
            logTrace( "ERROR!  Unable to start discovery!" )
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didFetchDevices: false, [] )
                self.processNextRequest()
            }
            
        }
        
    }
    
    
    private func _fetchDirectoriesFrom(_ share: SMBShare, _ atPath: String, _ delegate: NASCentralDelegate ) {
//        logVerbose( "[ %@/%@ ]  returnCsvFiles[ %@ ]", share.name, atPath, stringFor( returnCsvFiles ) )
        if let share = selectedShare {
            self.delegate          = delegate
            workingAccessKey.share = share.name
            
            smbCentral.returnCsvFiles = returnCsvFiles
            smbCentral.fetchDirectoriesFor( share, atPath, self )
        }
        else {
            logTrace( "ERROR!  selectedShare NOT set!" )
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didFetchDirectories: false, [] )
                self.processNextRequest()
            }
            
        }
        
    }
    
    
    private func _fetchFileOn(_ share: SMBShare, _ fullpath: String, _ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        smbCentral.fetchFileOn( share, fullpath, self )
    }
    
    
    private func _fetchShares(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        smbCentral.fetchSharesOnConnectedDevice( self )
    }
    
    
    private func _saveDataStoreAccessKey(_ path: String, _ delegate: NASCentralDelegate ) {
        logVerbose( "[ %@ ]", path )
        workingAccessKey.path = path
        dataStoreAccessKey    = workingAccessKey
        
        DispatchQueue.main.async {
            delegate.nasCentral( self, didSaveDataStoreAccessKey: true )
            self.processNextRequest()
        }
        
    }
    
    
    private func _saveData(_ data: Data, _ share: SMBShare, _ fullpath: String, _ delegate: NASCentralDelegate  ) {
//        logTrace()
        self.delegate = delegate

        smbCentral.saveData( data, selectedShare!, fullpath, self )
    }
    
    

    // MARK: Timer Methods
    
    @objc func timerFired() {
        logTrace()
        discoveryTimer?.invalidate()

        smbCentral.stopDiscovery()
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchDevices: true, self.smbCentral.deviceArray )
            self.processNextRequest()
        }
        
    }

    
}



// MARK: Session Methods

extension NASCentral {
    
    private func _compareLastUpdatedFiles(_ delegate: NASCentralDelegate ) {
//        logTrace()
        let     fullPath = dataStoreAccessKey.path + "/" + Filenames.lastUpdated
        
        self.delegate = delegate
        currentFilename = Filenames.lastUpdated
        
        smbCentral.readFileAt( fullPath, self )
    }

    
    private func _copyAllImagesFromDeviceToNas(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        loadDevicePicturesIntoFileUrlArray()
        deleteFilesFromNas()
    }
    

    private func _copyAllImagesFromNasToDevice(_ delegate: NASCentralDelegate ) {
//        logTrace()
        let     fullPath = dataStoreAccessKey.path + "/" + DirectoryNames.pictures
        
        self.delegate = delegate
        
        smbCentral.fetchFilesAt( fullPath, self )
    }
    
    
    private func _copyDatabaseFromDeviceToNas(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        loadDatabaseFilesIntoDeviceUrlArray()
        deleteFilesFromNas()
    }
    
    
    private func _copyDatabaseFromNasToDevice(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        loadDatabaseFilesIntoDeviceUrlArray()
        deleteFilesFromDevice()
        
        if dbDataArray.count == 4 {
            var allFilesTransferred = true
            
            for tuple in dbDataArray {
                let fileUrl  = documentDirectoryURL.appendingPathComponent( tuple.0 )
                let result   = fileManager.createFile( atPath: fileUrl.path, contents: tuple.1, attributes: nil )
                
                logVerbose( "%@ [ %@ ]", ( result ? "Created" : "FAILED to create" ), fileUrl.path )
                
                if !result {
                    allFilesTransferred = false
                    break
                }
                
            }
            
            if allFilesTransferred {
                self.delegate?.nasCentral( self, didCopyDatabaseFromNasToDevice:  true )
            }
            else {
                deleteFilesFromDevice()
                readNextRootFileFromNas()
            }
            
        }
        else {
            readNextRootFileFromNas()
        }
        
        dbDataArray = []
    }
    
    
    private func _deleteImage(_ filename: String, _ delegate: NASCentralDelegate ) {
//        logVerbose( "[ %@ ]", filename )
        currentFilename = filename
        self.delegate   = delegate

        var     imageUrl = URL( fileURLWithPath: dataStoreAccessKey.path )
        
        imageUrl = imageUrl.appendingPathComponent( DirectoryNames.pictures )
        imageUrl = imageUrl.appendingPathComponent( filename )
        
        smbCentral.deleteFileAt( imageUrl.path, self )
    }
    
    
    private func _endSession(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        smbCentral.endSession( self )
    }
    
    
    private func _fetchDbFiles(_ delegate: NASCentralDelegate ) {
        logTrace()
        dbFilenameArray = [Filenames.database, Filenames.databaseShm, Filenames.databaseWal, Filenames.lastUpdated]
        self.delegate   = delegate
        missingDbFiles  = []
        dbDataArray     = []

        let     fullPath = dataStoreAccessKey.path + "/" + Filenames.database

        smbCentral.readFileAt( fullPath, self )
    }
    
    
    private func _fetchFileAt(_ fullPathToFile: String, _ delegate: NASCentralDelegate ) {
        logVerbose( "[ %@ ]", fullPathToFile )
        self.delegate = delegate

        smbCentral.readFileAt( fullPathToFile, self )
    }
    
    
    private func _fetchImage(_ filename: String, _ delegate: NASCentralDelegate ) {
        logVerbose( "[ %@ ] last[ %@ ]", filename, currentFilename )

        let     fullPath  = dataStoreAccessKey.path + "/" + DirectoryNames.pictures + "/" + filename

        currentFilename = filename
        self.delegate   = delegate

        smbCentral.readFileAt( fullPath, self )
    }
    
    
    private func _fetchImageNames(_ delegate: NASCentralDelegate ) {
//        logTrace()
        let     fullPath = dataStoreAccessKey.path + "/" + DirectoryNames.pictures
        
        self.delegate = delegate
        
        smbCentral.fetchFilesAt( fullPath, self )
    }
    
    
    private func _lockNas(_ delegate: NASCentralDelegate ) {
//        logTrace()
        let     fullPath = dataStoreAccessKey.path + "/" + Filenames.lockFile
        
        self.delegate   = delegate
        currentFilename = Filenames.lockFile
        
        smbCentral.readFileAt( fullPath, self )
    }
    
    
    private func _saveImageData(_ imageData: Data, filename: String, _ delegate: NASCentralDelegate ) {
//        logTrace()
        let     fullPath  = dataStoreAccessKey.path + "/" + DirectoryNames.pictures + "/" + filename

        currentFilename = filename
        self.delegate   = delegate
        
        smbCentral.writeData( imageData, toFileAt: fullPath, self )
    }
    
    
    private func _startSession(_ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            documentDirectoryURL = url
        }
        else {
            logTrace( "ERROR:  Unable to load documentDirectoryURL" )
            documentDirectoryURL = URL( fileURLWithPath: "" )
        }

        smbCentral.startSession( dataStoreAccessKey, self )
    }
    
    
    private func _unlockNas(_ delegate: NASCentralDelegate ) {
//        logTrace()
        let     fullPath = dataStoreAccessKey.path + "/" + Filenames.lockFile
        
        self.delegate = delegate
        smbCentral.deleteFileAt( fullPath, self )
    }

    
    
    // MARK: These methods do double-duty
    
    private func _fetchFilesAt(_ path: String, _ delegate: NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        smbCentral.fetchFilesAt( path, self )
    }
    
    
    private func _openShare(_ share: SMBShare, _ delegate: NASCentralDelegate ) {
//        logTrace()
        var didOpenShare = false
                
        selectedShare = nil
        
        share.open {
            (error) in
            
            if let myError = error {
                logVerbose( "ERROR!  Unable to open share[ %@ ] ... [ %@ ]", share.name, myError.localizedDescription )
                share.close( nil )
            }
            else {
//                logVerbose( "Opened share[ %@ ]", share.name )
                didOpenShare = true
                self.selectedShare = share
            }
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didOpenShare: didOpenShare, share )
                self.processNextRequest()
            }
            
        }
        
    }
    
    

    // MARK: Session Utility Methods
    
    private func deleteFilesFromDevice() {
//        logTrace()
        for fileUrl in deviceUrlsToDeleteArray {
            do {
                if fileManager.fileExists(atPath: fileUrl.path ) {
                    try fileManager.removeItem( at: fileUrl )
                    logVerbose( "Deleted [ %@ ]", fileUrl.lastPathComponent )
                }
                else {
                    logVerbose( "Doesn't Exist [ %@ ] ", fileUrl.lastPathComponent )
                }
                
            }
            catch let error as NSError {
                logVerbose( "Error: [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
            }
            
        }
        
        deviceUrlsToDeleteArray.removeAll()
    }
        
        
    private func deleteFilesFromNas() {
//        logTrace()
        if deviceUrlsToDeleteArray.isEmpty {
            let     path = currentCommand == .CopyDatabaseFromDeviceToNas ? "": DirectoryNames.pictures
            
            logTrace( "nothing to delete ... start transfer" )
            readAndWriteDeviceDataToNasAt( path )
        }
        else {
            var     fullPath = dataStoreAccessKey.path + "/"
            let     url      = deviceUrlsToDeleteArray.last!
           
            if currentCommand == .CopyAllImagesFromDeviceToNas{
                fullPath += DirectoryNames.pictures + "/"
            }
            
            fullPath += url.lastPathComponent
            deviceUrlsToDeleteArray.removeLast()
            logVerbose( "[ %@ ]", url.lastPathComponent )

            smbCentral.deleteFileAt( fullPath, self )
        }

    }

            
    private func loadDatabaseFilesIntoDeviceUrlArray() {
//        logTrace()
        deviceUrlArray         .removeAll()
        deviceUrlsToDeleteArray.removeAll()

        for filename in Constants.databaseFilenameArray {
            let     fileUrl = documentDirectoryURL.appendingPathComponent( filename )
            
            deviceUrlArray.append( fileUrl )
//            logVerbose( "[ %@ ]", fileUrl.path )
        }
        
        deviceUrlsToDeleteArray.append( contentsOf: deviceUrlArray )
    }
        
        
    private func loadDevicePicturesIntoFileUrlArray() {
//        logTrace()
        var     filenameArray        = [String].init()
        let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
        
        deviceUrlArray         .removeAll()
        deviceUrlsToDeleteArray.removeAll()

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
                        deviceUrlArray.append( fileUrl )
//                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
            deviceUrlsToDeleteArray.append( contentsOf: deviceUrlArray )
        }
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
    }

    
    private func readNextRootFileFromNas() {
//        logTrace()
        if let fileUrl = deviceUrlArray.last {
            let     fullPath = dataStoreAccessKey.path + "/" + fileUrl.lastPathComponent
        
            currentFilename = fileUrl.lastPathComponent
            logVerbose( "[ %@ ]", currentFilename )
            
            smbCentral.readFileAt( fullPath, self )
        }
        else {
            logTrace( "ERROR!  Unable to unwrap deviceUrlArray.last!" )
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didCopyDatabaseFromNasToDevice: false )
                self.processNextRequest()
            }
            
        }
        
    }
    
    
    private func readNextImageFromNas() {
        if nasImageFileArray.isEmpty {
            logTrace( "Done!" )
            DispatchQueue.main.async {
                if self.currentCommand == .CopyAllImagesFromNasToDevice {
                    self.delegate?.nasCentral( self, didCopyAllImagesFromNasToDevice: true )
                }
                else {
                    self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: true )
                }
                
                self.processNextRequest()
            }
            
        }
        else {
            if let imageFile = nasImageFileArray.last {
                let     fullPath = dataStoreAccessKey.path + "/" + DirectoryNames.pictures + "/" + imageFile.name

                currentFilename = imageFile.name
                logVerbose( "[ %@/%@ ]", DirectoryNames.pictures, currentFilename )
                
                smbCentral.readFileAt( fullPath, self )
            }
            else {
                logTrace( "ERROR!  Unable to extract last object from nasImageArray" )
                DispatchQueue.main.async {
                    if self.currentCommand == .CopyAllImagesFromNasToDevice {
                        self.delegate?.nasCentral( self, didCopyAllImagesFromNasToDevice: false )
                    }
                    else {
                        self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: false )
                    }

                    self.processNextRequest()
                }
                
            }

        }
        
    }
        
        

}



// MARK: SMBCentralDelegate Methods

extension NASCentral: SMBCentralDelegate {
    
    // MARK: Access Callbacks
    
    func smbCentral(_ smbCentral: SMBCentral, didFindFolder: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didFindFolder ) )
        
        DispatchQueue.main.async {
            if self.currentCommand == .CanSeeNasFolders {
                self.delegate?.nasCentral( self, canSeeNasFolders: didFindFolder )
            }
            else {
                self.delegate?.nasCentral( self, canSeeNasDataSourceFolders: didFindFolder )
            }
            
            self.processNextRequest()
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didCloseShareAndDevice: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didCloseShareAndDevice ) )

        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didCloseShareAndDevice: true )
            self.processNextRequest()
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didConnectToDevice: Bool ) {
//        logVerbose( "[ %@ ]", stringFor( didConnectToDevice ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didConnectToDevice: didConnectToDevice, self.selectedDevice! )
            self.processNextRequest()
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didCreateDirectory: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didCreateDirectory ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didCreateDirectory: didCreateDirectory )
            self.processNextRequest()
        }
        
    }
        

    func smbCentral(_ smbCentral: SMBCentral, didFetchDirectories: Bool, _ directoryArray: [SMBFile] ) {
//        logVerbose( "[ %@ ]", stringFor( didFetchDirectories ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchDirectories: didFetchDirectories, directoryArray )
            self.processNextRequest()
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didFetchFile: Bool, _ fileData: Data) {
//        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchFile: didFetchFile, fileData )
            self.processNextRequest()
        }
        
    }
        
        
    func smbCentral(_ smbCentral: SMBCentral, didFetchShares: Bool, _ shares: [SMBShare] ) {
//        logVerbose( "[ %@ ]", stringFor( didFetchShares ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchShares: didFetchShares, shares )
            self.processNextRequest()
        }
        
    }
    

    
    // MARK: Session Callbacks
    
    func smbCentral(_ smbCentral: SMBCentral, didDeleteFile: Bool, _ filename: String ) {
//        logVerbose( "[ %@ ][ %@ ]", stringFor( didDeleteFile ), filename )

        if currentCommand == .CopyDatabaseFromDeviceToNas || currentCommand == .CopyAllImagesFromDeviceToNas {
            if deviceUrlsToDeleteArray.count != 0 {
                deleteFilesFromNas()
            }
            else {
                let     path = currentCommand == .CopyDatabaseFromDeviceToNas ? "": DirectoryNames.pictures
                
                readAndWriteDeviceDataToNasAt( path )
            }
            
        }
        else if currentCommand == .DeleteImage {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didDeleteImage: didDeleteFile )
                self.processNextRequest()
            }
            
        }
        else if currentCommand == .UnlockNas {
            logVerbose( "[ %@ ][ %@ ]", stringFor( didDeleteFile ), filename )

            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didUnlockNas: didDeleteFile )
                self.processNextRequest()
            }
            
        }
        else {
            logTrace( "SBH!" )
        }

    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didEndSession: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didEndSession ) )
        sessionActive = false
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didEndSession: didEndSession )
            self.processNextRequest()
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didFetchFiles: Bool, _ fileArray: [SMBFile] ) {
//        logVerbose( "[ %@ ] returned [ %d ] files", stringFor( didFetchFiles ), fileArray.count )
        
        if currentCommand == .FetchImageNames {
            var     imageNameArray = [String].init()
            
            for smbFile in fileArray {
                imageNameArray.append( smbFile.name )
            }
            
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didFetch: imageNameArray )
                self.processNextRequest()
            }
            
        }
        else if currentCommand == .FetchFilesAt {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didFetchFiles: didFetchFiles, fileArray )
                self.processNextRequest()
            }
            
        }
        else {
            if didFetchFiles {
                nasImageFileArray = fileArray
            }
            else {
                logTrace( "ERROR!  Unable to retrieve image files from NAS ... assuming there are none!" )
            }
            
            deleteFilesFromDevice()
            readNextImageFromNas()
        }

    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didReadFile: Bool, _ fileData: Data) {
        logVerbose( "[ %@ ]", stringFor( didReadFile ) )
        
        switch currentCommand {
        
        case .CompareLastUpdatedFiles:      if didReadFile {
                                                compareLastUpdatedFiles( fileData )
                                            }
                                            else {
                                                DispatchQueue.main.async {
                                                    self.delegate?.nasCentral( self, didCompareLastUpdatedFiles: LastUpdatedFileCompareResult.equal, lastUpdatedBy: NSLocalizedString( "Title.Unknown", comment: "Unknown" ) )
                                                    self.processNextRequest()
                                                }
                                            
                                            }
            
        case .CopyAllImagesFromNasToDevice: if didReadFile {
                                                writeNasImageDataToDevice( fileData )
                                            }

                                            nasImageFileArray.removeLast()
                                            readNextImageFromNas()

        case .CopyDatabaseFromNasToDevice:  writeNasRootDataToDevice( fileData )
            
        case .FetchDbFiles:                 let dbFilename = dbFilenameArray.first!
            
                                            if didReadFile {
                                                dbDataArray.append( ( dbFilename, fileData ) )
                                            }
                                            else{
                                                logVerbose( "FetchDbFiles - Could NOT Read [ %@ ] ", dbFilename )
                                                missingDbFiles.append( dbFilename )
                                            }
            
                                            dbFilenameArray.removeFirst()

                                            if dbFilenameArray.isEmpty {
                                                DispatchQueue.main.async {
                                                    self.delegate?.nasCentral( self, missingDbFiles: self.missingDbFiles )
                                                    self.processNextRequest()
                                                }

                                            }
                                            else {
                                                let fullPath = dataStoreAccessKey.path + "/" + dbFilenameArray.first!
                                                
                                                smbCentral.readFileAt( fullPath, self )
                                            }

        case .FetchImage:                   var     imageAvailable = false
                                            var     myImage        = UIImage.init()

                                            if didReadFile {
                                                if let image = UIImage.init( data: fileData ) {
                                                    myImage = image
                                                    imageAvailable = true
                                                }
                                                else {
                                                    logTrace( "ERROR!  Unable to create image from data!" )
                                                }
                                                
                                            }
                                            
                                            DispatchQueue.main.async {
                                                self.delegate?.nasCentral( self, didFetchImage: imageAvailable, image: myImage, filename: self.currentFilename )
                                                self.processNextRequest()
                                            }
                                            

        case .LockNas:                      if !didReadFile {
                                                logTrace( "Creating lockfile" )
                                                createLockFile()
                                                return
                                            }

                                            analyzeLockFile( fileData )

                                            DispatchQueue.main.async {
                                                self.delegate?.nasCentral( self, didLockNas: self.deviceAccessControl.byMe )
                                                self.processNextRequest()
                                            }

        default:                            logTrace( "SBH!" )
        }
       
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ][ %@ ]", stringFor( didStartSession ), stringForCommand( currentCommand ) )
        
        if currentCommand == .StartDataSourceSession {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didStartDataSourceSession: didStartSession, share: smbCentral.connectedShare )
                self.processNextRequest()
            }
            
            return
        }
        
        sessionActive = didStartSession

        if reEstablishConnection && didStartSession {
            reEstablishConnection = false
            logTrace( "Session re-established" )
            processNextRequest( false )
        }
        else {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didStartSession: didStartSession )
                self.processNextRequest()
            }
            
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didWriteFile: Bool ) {
        logVerbose( "[ %@ ][ %@ ]", stringFor( didWriteFile ), currentFilename )

        switch currentCommand {
        
        case .CopyDatabaseFromDeviceToNas,
             .CopyAllImagesFromDeviceToNas:

                                    if didWriteFile {
                                        deviceUrlArrayIndex += 1
                                        
                                        if deviceUrlArrayIndex < deviceUrlArray.count {
                                            let     path = currentCommand == .CopyDatabaseFromDeviceToNas ? "": DirectoryNames.pictures

                                            readAndWriteDeviceDataToNasAt( path )
                                        }
                                        else {
                                            logVerbose( "Transferred [ %d ] files to NAS drive", deviceUrlArrayIndex )
                                            
                                            deviceUrlArrayIndex = 0
                                            
                                            DispatchQueue.main.async {
                                                if self.currentCommand == .CopyDatabaseFromDeviceToNas {
                                                    self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: true )
                                                }
                                                else {
                                                    self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: true )
                                                }
                                                
                                                self.processNextRequest()
                                            }
                                                
                                        }

                                    }
                                    else {
                                        logTrace( "ERROR!  overwrite NAS data failed!" )
                                        
                                        DispatchQueue.main.async {
                                            if self.currentCommand == .CopyDatabaseFromDeviceToNas {
                                                self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: false )
                                            }
                                            else {
                                                self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: false )
                                            }
                                            
                                            self.processNextRequest()
                                        }
                                        
                                    }
            
            
        case .LockNas:              deviceAccessControl.reset()
                                    deviceAccessControl.locked = true

                                    if didWriteFile {
                                        deviceAccessControl.byMe      = true
                                        deviceAccessControl.ownerName = deviceName
                                        logVerbose( "Created lock file\n    %@", deviceAccessControl.descriptor() )
                                    }
                                    else {
                                        deviceAccessControl.ownerName = "Unknown"
                                        logVerbose( "ERROR!!!  Lock file create failed!    %@", deviceAccessControl.descriptor() )
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.delegate?.nasCentral( self, didLockNas: self.deviceAccessControl.byMe )
                                        self.processNextRequest()
                                    }

            
        case .SaveImageData:        DispatchQueue.main.async {
                                        self.delegate?.nasCentral( self, didSaveImageData: didWriteFile, filename: self.currentFilename )
                                        self.processNextRequest()
                                    }

        
        default:                    logTrace( "SBH!" )
        }
               
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didSaveData: Bool ) {
//        logVerbose( "[ %@ ]", stringFor( didSaveData ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didSaveData: didSaveData )
            self.processNextRequest()
        }
        
    }
    
    
    
    // MARK: Session Callback Utility Methods

    private func analyzeLockFile(_ fileData: Data ) {
        let     lockFileContents = String( decoding: fileData, as: UTF8.self )
        let     components       = lockFileContents.components( separatedBy: GlobalConstants.separatorForLockfileString )
        let     deviceId         = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"

        deviceAccessControl.reset()
        
        if components.count == 2 {
            let     lockDeviceId   = components[1]
            let     lockDeviceName = components[0]
            let     byMe           = ( deviceName == lockDeviceName ) && ( deviceId == lockDeviceId )
            
            deviceAccessControl.byMe      = byMe
            deviceAccessControl.locked    = true
            deviceAccessControl.ownerName = lockDeviceName
            logVerbose( "From existing lock file\n    %@", deviceAccessControl.descriptor() )
        }
        else {
            logVerbose( "ERROR!  lockMessage NOT properly formatted\n    [ %@ ]", lockFileContents )

            if lockFileContents.count == 0 {
                createLockFile()

                deviceAccessControl.byMe      = true
                deviceAccessControl.locked    = true
                deviceAccessControl.ownerName = deviceName
                logVerbose( "Overriding\n    %@", deviceAccessControl.descriptor() )
            }
            
        }
        
    }
    
    
    private func compareLastUpdatedFiles(_ nasData: Data ) {
        var     compareResult = LastUpdatedFileCompareResult.fileNotFound
        let     formatter     = DateFormatter()
        var     updatedBy     = NSLocalizedString( "Title.Unknown", comment: "Unknown" )
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     deviceFileUrl = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
            
            if fileManager.fileExists(atPath: deviceFileUrl.path ) {
                
                if let deviceFileData = fileManager.contents( atPath: deviceFileUrl.path ) {
                    let     deviceDateString = String( decoding: deviceFileData, as: UTF8.self )
                    let     deviceComponents = deviceDateString.components(separatedBy: GlobalConstants.separatorForLastUpdatedString )
                    let     deviceDate       = formatter.date( from: deviceComponents[0] )
                    let     nasDateString    = String( decoding: nasData, as: UTF8.self )
                    let     nasComponents    = nasDateString.components(separatedBy: GlobalConstants.separatorForLastUpdatedString )
                    let     nasDate          = formatter.date( from: nasComponents[0] )
                    
                    if let dateOnNas = nasDate?.timeIntervalSince1970, let dateOnDevice = deviceDate?.timeIntervalSince1970 {
                        if dateOnNas < dateOnDevice {
                            compareResult = LastUpdatedFileCompareResult.deviceIsNewer
                        }
                        else if dateOnDevice < dateOnNas {
                            compareResult = LastUpdatedFileCompareResult.nasIsNewer
                        }
                        else {
                            compareResult = LastUpdatedFileCompareResult.equal
                        }
                        
                        if nasComponents.count == 2 {
                            updatedBy = nasComponents[1]
                        }
                        
                    }
                    else {
                        logTrace( "ERROR!  Could NOT unwrap dateOnNas or dateOnDevice!" )
                    }
                    
                    
                }
                else {
                    logTrace( "ERROR!  Could NOT unwrap deviceFileData!" )
                }

            }
            else {
                logTrace( "LastUpdated file does NOT Exist on Device" )
            }

        }
        else {
            logTrace( "ERROR!  Could NOT unwrap documentDirectoryURL!" )
        }

        logVerbose( "[ %@ ] by [ %@ ]", descriptionForCompare( compareResult ), updatedBy )
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didCompareLastUpdatedFiles: compareResult, lastUpdatedBy: updatedBy )
            self.processNextRequest()
        }
        
    }
    
    
    private func createLockFile() {
//        logTrace()
        let     deviceId    = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     fullPath    = dataStoreAccessKey.path + "/" + Filenames.lockFile
        let     lockMessage = deviceName + GlobalConstants.separatorForLockfileString + deviceId
        let     fileData    = Data( lockMessage.utf8 )
        
        currentFilename = Filenames.lockFile
        
        DispatchQueue.main.async {
            self.smbCentral.writeData( fileData, toFileAt: fullPath, self )
        }
        
    }
    
    
    private func readAndWriteDeviceDataToNasAt(_ localPath: String ) {
        if deviceUrlArray.isEmpty {
//            logTrace( "Done!" )
            DispatchQueue.main.async {
                if self.currentCommand == .CopyDatabaseFromDeviceToNas {
                    self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: true )
                }
                else {
                    self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: true )
                }
                
                self.processNextRequest()
            }
            
            return
        }
        
        currentFilename = deviceUrlArray[deviceUrlArrayIndex].lastPathComponent

        if let fileData = fileManager.contents( atPath: deviceUrlArray[deviceUrlArrayIndex].path ) {
            var     fullPath = dataStoreAccessKey.path + "/"
            
            if !localPath.isEmpty {
                fullPath += localPath + "/"
            }
            
            fullPath += currentFilename
            
            logVerbose( "[ %@ ]", currentFilename )
            DispatchQueue.main.async {
                self.smbCentral.writeData( fileData, toFileAt: fullPath, self )
            }
            
        }
        else {
            logVerbose( "ERROR!  Could not un-wrap data for [ %@ ]", currentFilename )
            
            if currentCommand == .CopyDatabaseFromDeviceToNas {
                DispatchQueue.main.async {
                    self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: false )
                    self.processNextRequest()
                }
                
            }
            else {
                logTrace( "SBH!" )
                processNextRequest()
            }
            
        }
        
    }
    
    
    private func writeNasRootDataToDevice(_ fileData: Data ) {
//        logTrace()
        var     successFlag = true
        
        if let targetUrl = deviceUrlArray.last {
            let result = fileManager.createFile( atPath: targetUrl.path, contents: fileData, attributes: nil )
            
            logVerbose( "%@ [ %@ ]", (result ? "Created" : "FAILED to create" ), targetUrl.path )

            deviceUrlArray.removeLast()
            
            if deviceUrlArray.count != 0 {
                readNextRootFileFromNas()
                return
            }
            
        }
        else {
            logTrace( "ERROR!  Could NOT unwrap targetUrl" )
            successFlag = false
        }
       
        DispatchQueue.main.async {
            switch self.currentCommand {
            case .CopyAllImagesFromDeviceToNas:         self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: successFlag )
            case .CopyDatabaseFromDeviceToNas:          self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas:  successFlag )
            case .CopyDatabaseFromNasToDevice:          self.delegate?.nasCentral( self, didCopyDatabaseFromNasToDevice:  successFlag )
            case .UnlockNas:                            self.delegate?.nasCentral( self, didUnlockNas: successFlag )
            default:                                    logTrace( "SBH!" )
           }

            self.processNextRequest()
        }
        
        logTrace( "Done!" )
    }
        

    private func writeNasImageDataToDevice(_ fileData: Data ) {
        var     targetUrl = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
        
        targetUrl = targetUrl.appendingPathComponent( currentFilename )
        
        let result = fileManager.createFile( atPath: targetUrl.path, contents: fileData, attributes: nil )
        
        logVerbose( "%@ [ %@ ]", (result ? "Created" : "FAILED to create" ), targetUrl.path )
    }
    

}
    


// MARK: Globally Accessible Definitions and Methods

struct LastUpdatedFileCompareResult {
    static let deviceIsNewer = Int( 0 )
    static let equal         = Int( 1 )
    static let nasIsNewer    = Int( 2 )
    static let fileNotFound  = Int( 3 )
}


func descriptionForCompare(_ lastUpdatedCompare: Int ) -> String {
    var     description = "Unknown"
    
    switch lastUpdatedCompare {
    case LastUpdatedFileCompareResult.deviceIsNewer:    description = "Device is Newer"
    case LastUpdatedFileCompareResult.equal:            description = "Equal"
    case LastUpdatedFileCompareResult.nasIsNewer:       description = "NAS is Newer"
    case LastUpdatedFileCompareResult.fileNotFound:     description = "File NOT Found"
    default:    break
    }

    return description
}


