//
//  NavigatorCentral.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/5/24.
//


import UIKit
import CoreData
import Photos



protocol NavigatorCentralDelegate: AnyObject {
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didAddMedia          : Bool, count: Int )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didDeleteMediaData   : Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetch imageNames  : [String] )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetchImage        : Bool, filename: String, image: UIImage )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase      : Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadMediaData   : Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didSaveImageData     : Bool )
}

// Now we provide a default implementation which makes them all optional
extension NavigatorCentralDelegate {
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didAddMedia          : Bool, count: Int ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didDeleteMediaData   : Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetch imageNames  : [String] ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetchImage        : Bool, filename: String, image: UIImage ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase      : Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadMediaData   : Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didSaveImageData     : Bool ) {}
}



class NavigatorCentral: NSObject {
    
    
    // MARK: Public Variables & Definitions
    
    weak var delegate: NavigatorCentralDelegate?
    
    var deviceAssetArrayOfArrays        = [[PHAsset]]()
    var didOpenDatabase                 = false
    var externalDeviceLastUpdatedBy     = ""
    var mediaFileDataReloaded           = false
    var mediaFileArrayOfArrays          = [[MediaFile]]()
    var missingDbFiles: [String]        = []
    var numberOfMediaFilesLoaded        = 0
    var numberOfDeviceAssetsLoaded      = 0
    var pleaseWaiting                   = false
    var resigningActive                 = false
    var sectionTitleArray: [String]     = []
    var stayOffline                     = false
    let userDefaults                    = UserDefaults.standard
    
    var dataSourceDescriptor: NASDescriptor {
        get {
            var     descriptor = NASDescriptor()
            
            if let descriptorString = userDefaults.string( forKey: UserDefaultKeys.dataSourceDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    descriptor.host         = components[0]
                    descriptor.netbiosName  = components[1]
                    descriptor.group        = components[2]
                    descriptor.userName     = components[3]
                    descriptor.password     = components[4]
                    descriptor.share        = components[5]
                    descriptor.path         = components[6]
                }
                
            }
            
            return descriptor
        }
        
        set ( newDescriptor ){
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               newDescriptor.host,      newDescriptor.netbiosName, newDescriptor.group,
                                               newDescriptor.userName,  newDescriptor.password,
                                               newDescriptor.share,     newDescriptor.path )
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.dataSourceDescriptor )
            userDefaults.synchronize()
        }
        
    }
    
    
    var dataSourceLocation: DataLocation {
        get {
            if dataSourceLocationBacking != .notAssigned {
                return dataSourceLocationBacking
            }
            
            if let locationString = userDefaults.string( forKey: UserDefaultKeys.dataSourceLocation ) {
                return dataLocationFor( locationString )
            }
            else {
                return .device
            }
            
        }
        
        set( location ) {
            var     oldLocation = DataLocationName.device
            var     newLocation = ""
            
            if let savedLocation = userDefaults.string( forKey: UserDefaultKeys.dataSourceLocation ) {
                oldLocation = savedLocation
            }
            
            switch location {
            case .device:       newLocation = DataLocationName.device
            case .nas:          newLocation = DataLocationName.nas
            case .shareNas:     newLocation = DataLocationName.shareNas
            default:            newLocation = DataLocationName.notAssigned
            }
            
            logVerbose( "[ %@ ] -> [ %@ ]", oldLocation, newLocation )
            
            dataSourceLocationBacking = location
            
            userDefaults.set( newLocation, forKey: UserDefaultKeys.dataSourceLocation )
            userDefaults.synchronize()
        }
        
    }
    
    
    var dataStoreLocation: DataLocation {
        get {
            if dataStoreLocationBacking != .notAssigned {
                return dataStoreLocationBacking
            }
            
            if let locationString = userDefaults.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                return dataLocationFor( locationString )
            }
            else {
                return .device
            }
            
        }
        
        set( location ) {
            var     oldLocation = DataLocationName.device
            var     newLocation = ""
            
            if let lastLocation = userDefaults.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                oldLocation = lastLocation
            }
            
            switch location {
            case .device:       newLocation = DataLocationName.device
            case .nas:          newLocation = DataLocationName.nas
            case .shareNas:     newLocation = DataLocationName.shareNas
            default:            newLocation = DataLocationName.device
            }
            
            logVerbose( "[ %@ ] -> [ %@ ]", oldLocation, newLocation )
            
            dataStoreLocationBacking = location
            
            userDefaults.set( newLocation, forKey: UserDefaultKeys.dataStoreLocation )
            userDefaults.synchronize()
        }
        
    }
    
    
    var dataStoreDescriptor: NASDescriptor {
        get {
            var     descriptor = NASDescriptor()
            
            if let descriptorString = userDefaults.string( forKey: UserDefaultKeys.dataStoreDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    descriptor.host         = components[0]
                    descriptor.netbiosName  = components[1]
                    descriptor.group        = components[2]
                    descriptor.userName     = components[3]
                    descriptor.password     = components[4]
                    descriptor.share        = components[5]
                    descriptor.path         = components[6]
                }
                
            }
            
            return descriptor
        }
        
        set ( newDescriptor ){
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               newDescriptor.host,      newDescriptor.netbiosName, newDescriptor.group,
                                               newDescriptor.userName,  newDescriptor.password,
                                               newDescriptor.share,     newDescriptor.path )
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.dataStoreDescriptor )
            userDefaults.synchronize()
        }
        
    }
    
    
    var deviceName: String {
        get {
            var     nameOfDevice = ""
            
            if let deviceNameString = userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
                if !deviceNameString.isEmpty && deviceNameString.count > 0 {
                    nameOfDevice = deviceNameString
                }
                
            }
            
            return nameOfDevice
        }
        
        
        set( newName ) {
            self.userDefaults.set( newName, forKey: UserDefaultKeys.deviceName )
            self.userDefaults.synchronize()
        }
        
    }
    
    
    var imageDuration: Int {
        get {
            return userDefaults.integer(forKey: UserDefaultKeys.imageDuration )
        }
        
        set( duration ) {
            self.userDefaults.set( duration, forKey: UserDefaultKeys.imageDuration )
            self.userDefaults.synchronize()
        }
        
    }
    
    
    var sortDescriptor: (String, Bool) {
        get {
            if let descriptorString = userDefaults.string(forKey: UserDefaultKeys.currentSortOption ) {
                let sortComponents = descriptorString.components(separatedBy: GlobalConstants.separatorForSorts )
                
                if sortComponents.count == 2 {
                    let     option    = sortComponents[0]
                    let     direction = ( sortComponents[1] == GlobalConstants.sortAscendingFlag )
                    
                    return ( option, direction )
                }
                
            }
            
            return ( SortOptions.byFilename, true )
        }
        
        set ( sortTuple ) {
            let descriptorString = sortTuple.0 + GlobalConstants.separatorForSorts + ( sortTuple.1 ? GlobalConstants.sortAscendingFlag : GlobalConstants.sortDescendingFlag )
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.currentSortOption )
            userDefaults.synchronize()
        }
        
    }
    
    

    // MARK: Private Variables & Definitions
    
    private var databaseUpdated             = false
    private var dataSourceLocationBacking   = DataLocation.notAssigned
    private var dataStoreLocationBacking    = DataLocation.notAssigned
    private var photoAssetsObject           : PhotoAssets!
    private var updateTimer                 : Timer!
    
    
    
    // MARK: Definitions shared with CommonExtensions
    
    struct Constants {
        static let databaseModel  = "NavigatorCentral"
        static let primedFlag     = "Primed"
        static let timerDuration  = Double( 300 )
    }
    
    struct OfflineImageRequestCommands {
        static let delete = 1
        static let fetch  = 2
        static let save   = 3
    }
    
    var backgroundTaskID        : UIBackgroundTaskIdentifier = .invalid
    let deviceAccessControl     = DeviceAccessControl.sharedInstance
    let fileManager             = FileManager.default
    var imageRequestQueue       : [(String, NavigatorCentralDelegate)] = []      // This queue is used to serialize NAS transactions while online
    var managedObjectContext    : NSManagedObjectContext!
    var nasCentral              = NASCentral.sharedInstance
    var notificationCenter      = NotificationCenter.default
    var offlineImageRequestQueue: [ImageRequest] = []                             // This queue is used to flush offline NAS image transactions to disk after we reconnect
    var openInProgress          = false
    var persistentContainer     : NSPersistentContainer!
    
    var updatedOffline: Bool {
        get {
            return flagIsPresentInUserDefaults( UserDefaultKeys.updatedOffline )
        }
        
        set ( setFlag ) {
            if setFlag {
                setFlagInUserDefaults( UserDefaultKeys.updatedOffline )
            }
            else {
                removeFlagFromUserDefaults( UserDefaultKeys.updatedOffline )
            }
            
        }
        
    }
    
        
    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = NavigatorCentral()        // Prevents anyone else from creating an instance
    
    
    
    // MARK: AppDelegate Methods
    
    func enteringBackground() {
        logTrace()
        resigningActive = true
        
//        stopTimer()
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enteringBackground ), object: self )
    }
    
    
    func enteringForeground() {
        logTrace()
        resigningActive = false
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enteringForeground ), object: self )
//        canSeeExternalStorage()
    }
    
    
    
    // MARK: Database Access Methods (Public)
    
    func openDatabaseWith(_ delegate: NavigatorCentralDelegate ) {
        
        if openInProgress {
            logTrace( "openInProgress ... do nothing" )
            return
        }
        
        if deviceAccessControl.updating {
            logTrace( "transferInProgress ... do nothing" )
            return
        }
        
        logTrace()
        self.delegate         = delegate
        didOpenDatabase       = false
        mediaFileDataReloaded = false
        openInProgress        = true
        persistentContainer   = NSPersistentContainer( name: Constants.databaseModel )
        
        persistentContainer.loadPersistentStores( completionHandler:
                                                    { ( storeDescription, error ) in
            
            if let error = error as NSError? {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else {
                self.loadCoreData()
                
                if !self.didOpenDatabase  {     // This is just in case I screw up and don't properly version the data model
                    self.deleteDatabase()       // TODO: Figure out if this is the right thing to do
                    self.loadCoreData()
                }
                
                self.loadBasicData()
                
                self.startTimer()
            }
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ), execute:  {
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                
                self.openInProgress = false
                delegate.navigatorCentral( self, didOpenDatabase: self.didOpenDatabase )
                
                if self.updatedOffline && !self.stayOffline {
                    self.persistentContainer.viewContext.perform {
                        self.processNextOfflineImageRequest()
                    }
                    
                }
                
            } )
            
        } )
        
    }
    
    
    
    // MARK: Entity Access/Modifier Methods (Public)
    
    func addMediaFrom(_ smbFileArray: [SMBFile], _ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            delegate.navigatorCentral( self, didAddMedia: false, count: 0 )
            return
        }
        
//        logTrace()
        persistentContainer.viewContext.perform {
            for smbFile in smbFileArray {
                let mediaFile = NSEntityDescription.insertNewObject( forEntityName: EntityNames.mediaFile, into: self.managedObjectContext ) as! MediaFile
                let pathUrl   = URL(fileURLWithPath: smbFile.path, isDirectory: false )
                
                mediaFile.filename     = smbFile.name
                mediaFile.guid         = UUID().uuidString
                mediaFile.keywords     = ""
                mediaFile.relativePath = pathUrl.deletingLastPathComponent().path
                
                self.saveContext()
            }
            
            delegate.navigatorCentral( self, didAddMedia: true, count: smbFileArray.count )
        }
        
    }
    
    
    func deleteAllMediaData(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            delegate.navigatorCentral( self, didDeleteMediaData: false )
            return
        }
        
        logTrace()
        persistentContainer.viewContext.perform {
            let mediaFileArray = self.flatMediaFileArray()

            for mediaFile in mediaFileArray {
                self.managedObjectContext.delete( mediaFile )
            }
            
            self.saveContext()
            
            delegate.navigatorCentral( self, didDeleteMediaData: true )
        }
        
    }
    
    
    func deviceAssetAt(_ indexPath: IndexPath ) -> PHAsset {
        let sectionArray = deviceAssetArrayOfArrays[indexPath.section]
        
        return sectionArray[indexPath.row]
    }
    
    
    func fetchMediaFilesWith(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
//        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.refetchMediaDataAndNotifyDelegate()
        }
        
    }
    
    
    func mediaFileAt(_ indexPath: IndexPath ) -> MediaFile {
        let sectionArray = mediaFileArrayOfArrays[indexPath.section]
        
        return sectionArray[indexPath.row]
    }
    
    
    func mediaFilesWith(_ keywordArray: [String] ) -> [MediaFile] {
        var searchResults: [MediaFile] = []
        
        for mediaFileArray in mediaFileArrayOfArrays {
            for mediaFile in mediaFileArray {
                if let filename = mediaFile.filename {
                    var saveIt = true
                    
                    for keyword in keywordArray {
                        if !keyword.isEmpty {
                            if !filename.uppercased().contains( keyword.uppercased() ) {
                                saveIt = false
                                break
                            }

                        }

                    }
                    
                    if saveIt {
                        searchResults.append( mediaFile )
                    }
                    
                }
                
            }
            
        }
        
        return searchResults
    }
    
    
    func mimeTypeFor(_ mediaFile: MediaFile ) -> String {
        var mimeType = FileMimeTypes.unsup  // Unsupported
        
        switch extensionFrom( mediaFile.filename! ).uppercased() {
        case SupportedFilenameExtensions.avi:       mimeType = FileMimeTypes.avi
        case SupportedFilenameExtensions.jpeg:      mimeType = FileMimeTypes.jpeg
        case SupportedFilenameExtensions.jpg:       mimeType = FileMimeTypes.jpg
        case SupportedFilenameExtensions.heic:      mimeType = FileMimeTypes.heic
        case SupportedFilenameExtensions.heif:      mimeType = FileMimeTypes.heif
        case SupportedFilenameExtensions.htm:       mimeType = FileMimeTypes.htm
        case SupportedFilenameExtensions.html:      mimeType = FileMimeTypes.html
        case SupportedFilenameExtensions.mov:       mimeType = FileMimeTypes.mov
        case SupportedFilenameExtensions.mp4:       mimeType = FileMimeTypes.mp4
        case SupportedFilenameExtensions.mpeg:      mimeType = FileMimeTypes.mpeg
        case SupportedFilenameExtensions.mpeg4:     mimeType = FileMimeTypes.mpeg4
        case SupportedFilenameExtensions.png:       mimeType = FileMimeTypes.png
        case SupportedFilenameExtensions.qt:        mimeType = FileMimeTypes.qt
        case SupportedFilenameExtensions.tif:       mimeType = FileMimeTypes.tif
        case SupportedFilenameExtensions.tiff:      mimeType = FileMimeTypes.tiff
        case SupportedFilenameExtensions.ts:        mimeType = FileMimeTypes.ts
        case SupportedFilenameExtensions.webm:      mimeType = FileMimeTypes.webm
        case SupportedFilenameExtensions.webp:      mimeType = FileMimeTypes.webp
        case SupportedFilenameExtensions.wmv:       mimeType = FileMimeTypes.wmv
        default:                                    break
        }
        
        return mimeType
    }
    
    
    func nameForCurrentSortOption() -> String {
        let sortAscending  = sortDescriptor.1
        let sortType       = sortDescriptor.0
        let sortTypeName   = nameForSortType( sortType )
        let name           = sortTypeName + ( sortAscending ? GlobalConstants.sortAscending : GlobalConstants.sortDescending )
        
        return name
    }
    
    
    func nextAssetAfter(_ indexPath: IndexPath ) -> IndexPath {
        let currentArray = deviceAssetArrayOfArrays[indexPath.section]
        
        if indexPath.row + 1 < currentArray.count {
            return IndexPath.init(row: indexPath.row + 1, section: indexPath.section )
        }
        else {
            if indexPath.section + 1 < deviceAssetArrayOfArrays.count {
                return IndexPath.init(row: 0, section: indexPath.section + 1 )
            }
            
        }
        
        return IndexPath.init(row: 0, section: 0 )
    }
    
    
    func nextMediaFileAfter(_ indexPath: IndexPath ) -> IndexPath {
        let currentArray = mediaFileArrayOfArrays[indexPath.section]
        
        if indexPath.row + 1 < currentArray.count {
            return IndexPath.init(row: indexPath.row + 1, section: indexPath.section )
        }
        else {
            if indexPath.section + 1 < mediaFileArrayOfArrays.count {
                return IndexPath.init(row: 0, section: indexPath.section + 1 )
            }
            
        }
        
        return IndexPath.init(row: 0, section: 0 )
    }
    
    
    func populateWith(_ phAssetArray: [PHAsset] ) {
        logVerbose( "processing [ %d ] phAssets", phAssetArray.count )
        deviceAssetArrayOfArrays   = []
        numberOfDeviceAssetsLoaded = 0
        sectionTitleArray          = []

        var currentMonth    = [PHAsset]()
        var identiferString = ""
        var month           = GlobalConstants.noSelection
        var year            = GlobalConstants.noSelection
        
        for index in 0..<phAssetArray.count {
            let phAsset   = phAssetArray[index]
            let dateTuple = phAsset.creationDateAsTuple()
            
            if dateTuple.0 != year || dateTuple.1 != month {
                if !currentMonth.isEmpty {
                    deviceAssetArrayOfArrays.append( currentMonth )
                    sectionTitleArray.append( String( format: "%d/%02d", year, month ) )
                    currentMonth = []
                }
                
                year  = dateTuple.0
                month = dateTuple.1
            }

            currentMonth.append( phAsset )
            
            if !identiferString.isEmpty {
                identiferString += GlobalConstants.separatorForIdentifierString
            }
            
            identiferString += phAsset.localIdentifier
        }

        numberOfDeviceAssetsLoaded = phAssetArray.count
        
        if !currentMonth.isEmpty {
            deviceAssetArrayOfArrays.append( currentMonth )
            sectionTitleArray.append( String( format: "%d/%02d", year, month ) )
        }

        if let _ = photoAssetsObject {
            self.persistentContainer.viewContext.perform {
                self.photoAssetsObject.identifiers = identiferString
                self.saveContext()
            }

        }
        
        startReverseGeoCoding()
    }
    
    
    func previousAssetBefore(_ indexPath: IndexPath ) -> IndexPath {
        if indexPath.row - 1 >= 0 {
            return IndexPath.init(row: indexPath.row - 1, section: indexPath.section )
        }
        else {
            if indexPath.section - 1 >= 0 {
                let mediaArray = deviceAssetArrayOfArrays[indexPath.section - 1]
                
                return IndexPath.init(row: mediaArray.count - 1, section: indexPath.section - 1 )
            }
            
        }
        
        return IndexPath.init(row: 0, section: 0 )
    }
    
    
    func previousMediaFileBefore(_ indexPath: IndexPath ) -> IndexPath {
        if indexPath.row - 1 >= 0 {
            return IndexPath.init(row: indexPath.row - 1, section: indexPath.section )
        }
        else {
            if indexPath.section - 1 >= 0 {
                let mediaArray = mediaFileArrayOfArrays[indexPath.section - 1]
                
                return IndexPath.init(row: mediaArray.count - 1, section: indexPath.section - 1 )
            }
            
        }
        
        return IndexPath.init(row: 0, section: 0 )
    }
    
    
    func reloadData(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.refetchMediaDataAndNotifyDelegate()
        }
        
    }
    
    

    // MARK: Methods shared with CommonExtensions (Public)
    
    func nameForImageRequest(_ command: Int ) -> String {
        var     name = "Unknown"
        
        switch command {
        case OfflineImageRequestCommands.delete:    name = "Delete"
        case OfflineImageRequestCommands.fetch:     name = "Fetch"
        default:                                    name = "Save"
        }
        
        return name
    }
    
    
    func nameForSortType(_ sortType: String ) -> String {
        var name = "Unknown"
        
        switch sortType {
        case SortOptions.byFilename:        name = SortOptionNames.byFilename
        case SortOptions.byRelativePath:    name = SortOptionNames.byRelativePath
        default:                             break
        }
        
        return name
    }
    
    
    func pictureDirectoryPath() -> String {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                do {
                    try fileManager.createDirectory( atPath: picturesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to create photos directory ... Error[ %@ ]", error.localizedDescription )
                    return ""
                }
                
            }
            
//            logVerbose( "picturesDirectory[ %@ ]", picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
        logTrace( "ERROR!  Could NOT find the documentDirectory!" )
        return ""
    }
    
    
    // Must be called from within persistentContainer.viewContext
    func processNextOfflineImageRequest() {
        
        if offlineImageRequestQueue.isEmpty {
            logTrace( "Done!" )
            updatedOffline = false
            
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                nasCentral.unlockNas( self )
            }
            
            deviceAccessControl.updating = false
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        else {
            guard let imageRequest = offlineImageRequestQueue.first else {
                logTrace( "ERROR!  Unable to remove request from front of queue!" )
                updatedOffline = false
                return
            }
            
            let command  = Int( imageRequest.command )
            let filename = imageRequest.filename ?? "Empty!"
            
            logVerbose( "pending[ %d ]  processing[ %@ ][ %@ ]", offlineImageRequestQueue.count, nameForImageRequest( command ), filename )
            
            switch command {
            case OfflineImageRequestCommands.delete:   nasCentral.deleteImage( filename, self )
                
//           case OfflineImageRequestCommands.fetch:    imageRequestQueue.append( (filename, delegate! ) )
//                                                      nasCentral.fetchImage( filename, self )
                
            case OfflineImageRequestCommands.save:     let result = fetchFromDiskImageFileNamed( filename )
                
                if result.0 {
                    nasCentral.saveImageData( result.1, filename: filename, self )
                }
                else {
                    logVerbose( "ERROR!  NAS does NOT have [ %@ ]", filename )
                    DispatchQueue.main.async {
                        self.processNextOfflineImageRequest()
                    }
                    
                }
            default:    break
            }
            
            managedObjectContext.delete( imageRequest )
            offlineImageRequestQueue.remove( at: 0 )
            
            saveContext()
        }
        
    }
    
    
    func saveContext() {        // Must be called from within a persistentContainer.viewContext
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
                
                if dataStoreLocation != .device {
                    databaseUpdated = true
                    
                    if stayOffline {
                        updatedOffline = true
                    }
                    
                    createLastUpdatedFile()
                }
                
            }
            
            catch let error as NSError {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func canSeeExternalStorage() {
        if dataStoreLocation == .device {
            deviceAccessControl.initForDevice()
            logVerbose( "on device ... %@", deviceAccessControl.descriptor() )
            return
        }
        
        // We must be on the NAS
        logVerbose( "[ %@ ]", nameForDataLocation( dataStoreLocation ) )
        
        if !stayOffline {
            nasCentral.emptyQueue()
            nasCentral.canSeeNasFolders( self )
        }

    }
    
    
    private func deleteDatabase() {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database )
        
        do {
            logVerbose( "attempting to delete database @ [ %@ ]", storeURL.path )
            try fileManager.removeItem( at: storeURL )
            
            userDefaults.removeObject( forKey: Constants.primedFlag )
            userDefaults.synchronize()
        }
        catch let error as NSError {
            logVerbose( "Error!  Unable delete store! ... Error[ %@ ]", error.localizedDescription )
        }
        
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllImageRequestObjects() {
        offlineImageRequestQueue = []
        
        do {
            let     request         : NSFetchRequest<ImageRequest> = ImageRequest.fetchRequest()
            let     fetchedRequests = try managedObjectContext.fetch( request )
            
            offlineImageRequestQueue = fetchedRequests.sorted( by:
            { (request1, request2) -> Bool in
                return request1.index < request2.index
            })
            
        }
        catch {
            logTrace( "Error!  Fetch failed!" )
        }
        
        logVerbose( "Found [ %d ] requests", offlineImageRequestQueue.count )
    }

    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllMediaData() {
        mediaFileArrayOfArrays   = []
        numberOfMediaFilesLoaded = 0
        
        do {
            let     request: NSFetchRequest<MediaFile> = MediaFile.fetchRequest()
            let     fetchedMediaFiles = try managedObjectContext.fetch( request )
            
            numberOfMediaFilesLoaded = fetchedMediaFiles.count
            logVerbose( "Retrieved [ %d ] media files ... sorting", numberOfMediaFilesLoaded )
            
            let sortTuple     = sortDescriptor
            let sortAscending = sortTuple.1
            let sortOption    = sortTuple.0
            
            switch sortOption {
            case SortOptions.byFilename:    sortByFilename(     fetchedMediaFiles, sortAscending )
            default:                        sortByRelativePath( fetchedMediaFiles, sortAscending )
            }

        }
        
        catch {
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllPhotoAssets() {
        deviceAssetArrayOfArrays   = []
        numberOfDeviceAssetsLoaded = 0
        sectionTitleArray          = []

        do {
            let     request: NSFetchRequest<PhotoAssets> = PhotoAssets.fetchRequest()
            var     fetchedPhotoAssets = try managedObjectContext.fetch( request )
            
            logVerbose( "Retrieved [ %d ] photoAssets object", fetchedPhotoAssets.count )
            
            switch fetchedPhotoAssets.count {
            case 0:                 photoAssetsObject = (NSEntityDescription.insertNewObject( forEntityName: EntityNames.photoAssets, into: self.managedObjectContext ) as! PhotoAssets)
                
                                    photoAssetsObject.identifiers = ""
                                    saveContext()

            case 1:                 photoAssetsObject = fetchedPhotoAssets.last
                
            default:                photoAssetsObject = fetchedPhotoAssets.last
                                    fetchedPhotoAssets.removeLast()
                                    
                                    for index in 0..<fetchedPhotoAssets.count {
                                        self.managedObjectContext.delete( fetchedPhotoAssets[index] )
                                    }
                
                                    saveContext()
            }

            // Now load the PHAssets using the identifiers stored in the object
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                if let identifiers = photoAssetsObject.identifiers {
                    let identifierArray = identifiers.components(separatedBy: GlobalConstants.separatorForIdentifierString )
                
                    logVerbose( "retrieved [ %d ] identifiers ... fetching phAssets", identifierArray.count )
                    if identifierArray.count > 0 {
                        let fetchOptions = PHFetchOptions()
                        
                        fetchOptions.sortDescriptors = [ NSSortDescriptor( key: GlobalConstants.sortByCreationDate, ascending: true ) ]
                        
                        let fetchedAssets = PHAsset.fetchAssets(withLocalIdentifiers: identifierArray, options: fetchOptions )
                        var phAssetArray  = [PHAsset]()
                        
                        fetchedAssets.enumerateObjects { ( phAsset, count, stop ) in
                            phAssetArray.append( phAsset )
                        }
                        
                        phAssetArray = phAssetArray.sorted(by: { phAsset1, phAsset2 in
                            phAsset1.creationDate! < phAsset2.creationDate!
                        })
                        
                        self.populateWith( phAssetArray )
                    }
                    
                }

            }
            
        }

        catch {
            logTrace( "Error!  Fetch failed!" )
        }
    
    }
    
    
    private func flatMediaFileArray() -> [MediaFile] {
        var flatArray: [MediaFile] = []
        
        for array in mediaFileArrayOfArrays {
            for mediaFile in array {
                if !flatArray.contains( mediaFile ) {
                    flatArray.append( mediaFile )
                }
                
            }
            
        }
        
        return flatArray
    }
    
    
    private func loadBasicData() {
        let primedFlag = userDefaults.bool( forKey: Constants.primedFlag )
        logVerbose( "primedFlag[ %@ ]", stringFor( primedFlag ) )
        
        // Load and sort our public convenience arrays and sample data when priming
        self.persistentContainer.viewContext.perform {
            if !primedFlag {
                let _ = self.pictureDirectoryPath()   // Creates the directory

                self.imageDuration = 5
               
                self.userDefaults.set( true, forKey: Constants.primedFlag )
                self.userDefaults.synchronize()
            }
            
            if self.dataSourceLocation == .device {
                self.fetchAllPhotoAssets()
                logVerbose( "Loaded Device Assets[ %d ]", self.numberOfDeviceAssetsLoaded )
            }
            else {
                self.fetchAllMediaData()
                logVerbose( "Loaded Media files[ %d ]", self.numberOfMediaFilesLoaded )
            }
            
        }
        
    }
    
    
    private func loadCoreData() {
        guard let modelURL = Bundle.main.url( forResource: Constants.databaseModel, withExtension: "momd" ) else {
            logTrace( "Error!  Could NOT load model from bundle!" )
            return
        }
        
        logVerbose( "modelURL[ %@ ]", modelURL.path )
        
        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else {
            logVerbose( "Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", modelURL.path )
            return
        }
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )
        
        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database  )
        
        logVerbose( "storeURL[ %@ ]", storeURL.path )
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options )
            
            self.didOpenDatabase = true
            logTrace( "added store to coordinator" )
        }
        catch {
            let     nsError = error as NSError
            
            logVerbose( "Error!  Unable migrate store[ %@ ]", nsError.localizedDescription )
        }
        
    }

    
    // Must be called from within a persistentContainer.viewContext
    private func refetchMediaDataAndNotifyDelegate() {
        fetchAllMediaData()
        
        DispatchQueue.main.async {
            self.delegate?.navigatorCentral( self, didReloadMediaData: true )
        }
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.mediaDataReloaded ), object: self )
    }
    

    private func startReverseGeoCoding() {
        logTrace( "Fill me in!" )
//    https://geocode.maps.co/reverse?lat=latitude&lon=longitude&api_key=api_key
    }
    
    
}



// MARK: Sorting Methods (Private)

extension NavigatorCentral {
    
    private func sortByFilename(_ fetchedMediaFiles: [MediaFile], _ sortAscending: Bool ) {
        mediaFileArrayOfArrays = []
        sectionTitleArray      = []

        if fetchedMediaFiles.count == 0 {
            logVerbose( "sortAscending[ %@ ] ... we have zero recipes!  Do nothing!", stringFor( sortAscending ) )
            return
        }
        
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedMediaFiles.sorted( by:
                    { (mediaFile1, mediaFile2) -> Bool in
                        if sortAscending {
                            mediaFile1.filename! < mediaFile2.filename!
                        }
                        else {
                            mediaFile1.filename! > mediaFile2.filename!
                        }
            
                    } )
        
        var     currentStartingCharacter  = ""
        var     workingArray: [MediaFile] = []
        
        for mediaFile in sortedArray {
            let     nameStartsWith: String = ( mediaFile.filename?.prefix(1).uppercased() )!
            
            if nameStartsWith == currentStartingCharacter {
                workingArray.append( mediaFile )
            }
            else {
                if !workingArray.isEmpty {
                    mediaFileArrayOfArrays.append( workingArray )
                    sectionTitleArray     .append( currentStartingCharacter )
                    workingArray = []
                }
                
                currentStartingCharacter = nameStartsWith
            }

        }
        
        if !workingArray.isEmpty {
            mediaFileArrayOfArrays.append( workingArray )
            sectionTitleArray     .append( currentStartingCharacter )
        }

    }
    
    
    private func sortByRelativePath(_ fetchedMediaFiles: [MediaFile], _ sortAscending: Bool ) {
        mediaFileArrayOfArrays = []
        sectionTitleArray      = []

        if fetchedMediaFiles.count == 0 {
            logVerbose( "sortAscending[ %@ ] ... we have zero media files!  Do nothing!", stringFor( sortAscending ) )
            return
        }
        
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedMediaFiles.sorted( by:
                            { (mediaFile1, mediaFile2) -> Bool in
                                if sortAscending {
                                    mediaFile1.relativePath! < mediaFile2.relativePath!
                                }
                                else {
                                    mediaFile1.relativePath! > mediaFile2.relativePath!
                                }
                    
                            } )
        
        // Now we create and load arrays for each new path
        var currentPath                        = ""
        var outputArrayOfArrays: [[MediaFile]] = []
        var pathArray:            [String]     = []
        var workingArray:         [MediaFile]  = []

        if let startingPath = sortedArray.first?.relativePath {
            currentPath = startingPath
        }

        for mediaFile in sortedArray {
            if currentPath == mediaFile.relativePath {
                workingArray.append( mediaFile )
            }
            else {
                if workingArray.count != 0 {
                    outputArrayOfArrays.append( workingArray )
                    pathArray          .append( removeRootPathFrom( currentPath ) )
                    
                    currentPath = mediaFile.relativePath ?? ""
                    workingArray = [mediaFile]
                }
                
            }
            
        }
        
        if workingArray.count != 0 {
            outputArrayOfArrays.append( workingArray )
            pathArray.append( removeRootPathFrom( currentPath ) )
        }
        
        // Finally, we sort the contents of all of the arrays in the outputArrayOfArrays
        for index in 0..<outputArrayOfArrays.count {
            let sortedArray = outputArrayOfArrays[index].sorted(by: 
            { (recipe1, recipe2) -> (Bool) in
                return sortAscending ? ( recipe1.filename!.uppercased() < recipe2.filename!.uppercased() ) : recipe1.filename!.uppercased() > recipe2.filename!.uppercased()
            })
            
            outputArrayOfArrays[index] = sortedArray
        }
        
        mediaFileArrayOfArrays = outputArrayOfArrays
        sectionTitleArray      = pathArray
    }

    
    
    // MARK: Sorting Utility Methods (Private)

    private func removeRootPathFrom(_ path: String ) -> String {
        let rootPath       = dataSourceDescriptor.path + "/"
        let pathComponents = path.components(separatedBy: rootPath )
        var truncatedPath  = "."
        
        if pathComponents.count == 2 {
            truncatedPath = pathComponents[1]
        }

        return truncatedPath
    }
    
    
}



// MARK: Timer Methods (Public)

extension NavigatorCentral {
    
    func startTimer() {
        if dataStoreLocation == .device {
            logTrace( "Database on device ... do nothing!" )
            return
        }
        
        if stayOffline {
            logTrace( "stay offline" )
            return
        }
        
        logTrace()
        if let timer = updateTimer {
            timer.invalidate()
        }
        
        DispatchQueue.main.async {
            self.updateTimer = Timer.scheduledTimer( withTimeInterval: Constants.timerDuration, repeats: false ) {
                (timer) in
                
                if self.deviceAccessControl.updating {
                    logTrace( "We are updating ... do nothing!" )
                }
                else if self.databaseUpdated {
                    self.databaseUpdated = false
                    logVerbose( "databaseUpdated[ true ]\n    %@", self.deviceAccessControl.descriptor() )
                    logTrace( "copying database to NAS" )
                    self.nasCentral.copyDatabaseFromDeviceToNas( self )

                }
                else {
                    logTrace( "ending NAS session" )
                    self.nasCentral.endSession( self )
                }
                
            }

        }
        
    }
    
    
    func stopTimer() {
        if dataStoreLocation == .device {
            logTrace( "Database on device ... do nothing!" )
            databaseUpdated = false
            return
        }
        
        if let timer = updateTimer {
            timer.invalidate()
        }

        logVerbose( "databaseUpdated[ %@ ]\n    %@", stringFor( databaseUpdated ), deviceAccessControl.descriptor() )
        
        if databaseUpdated {
            
            if !stayOffline {
                DispatchQueue.global().async {

                    // The OS calls this block if we don't finish in time
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Finish copying DB to External Device" ) {
                        if self.dataStoreLocation == .nas || self.dataStoreLocation == .shareNas {
                            logVerbose( "queueContents[ %@ ]", self.nasCentral.queueContents() )
                        }

                        logTrace( "We ran out of time!  Killing background task..." )
                        UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
                        
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }
                    
                    if self.deviceAccessControl.updating {
                        logTrace( "we are updating the external device ... do nothing, just let the process complete!" )
                    }
                    else {
                        self.databaseUpdated = false
                        self.deviceAccessControl.updating = true
                        
                        logTrace( "copying database to NAS" )
                        self.nasCentral.copyDatabaseFromDeviceToNas( self )
                    }
                    
                }

            }
            
        }
        else {
            if !deviceAccessControl.byMe {
                logTrace( "do nothing!" )
                return
            }
            
            if !stayOffline {
                DispatchQueue.global().async {

                    // The OS calls this block if we don't finish in time
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Remove lock file" ) {
                        if self.dataStoreLocation == .nas || self.dataStoreLocation == .shareNas {
                            logVerbose( "queueContents[ %@ ]", self.nasCentral.queueContents() )
                        }

                        logTrace( "We ran out of time!  Ending background task #2..." )
                        UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
                        
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }
                    
                    if self.deviceAccessControl.updating {
                        logTrace( "we are updating the external device ... do nothing, just let the process complete!" )
                    }
                    else {
                        logTrace( "removing lock file" )
                        self.nasCentral.unlockNas( self )
                    }
                    
                }
                
            }
            
        }
        
    }
    

}
