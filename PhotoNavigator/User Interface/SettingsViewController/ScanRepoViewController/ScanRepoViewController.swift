//
//  ScanRepoViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 6/17/24.
//


import UIKit
import Photos



class ScanRepoViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var deviceShareLabel: UILabel!
    @IBOutlet weak var pathLabel       : UILabel!
    @IBOutlet weak var myTextView      : UITextView!
    @IBOutlet weak var startButton     : UIButton!
    @IBOutlet weak var stopButton      : UIButton!
    
    
    
    // MARK: Private Variables
    
    private let cloudCentral            = CloudCentral.sharedInstance
    private var connectedShare          : SMBShare!
    private var currentPath             = ""
    private var directoryArray          : [SMBFile] = []
    private var directoryContentsArray  = [FileDescriptor].init()
    private let fileManager             = FileManager.default
    private let nasCentral              = NASCentral.sharedInstance
    private var networkPath             = ""
    private let navigatorCentral        = NavigatorCentral.sharedInstance
    private var numberOfFilesSkipped    = 0
    private var numberOfMediaAdded      = 0
    private var rootUrl                 = URL.init( fileURLWithPath: "" )
    private var startingUrl             = URL.init( fileURLWithPath: "" )
    private var scanning                = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.ScanMediaRepository", comment: "Scan Media Repository" )
        myTextView.text = ""
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadLabels()
        configureControls()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func startButtonTouched(_ sender: UIButton) {
        logTrace()
        scanning = true
        configureControls()
        
        myTextView.text = ""
        
        numberOfFilesSkipped = 0
        numberOfMediaAdded   = 0
        
        if navigatorCentral.dataSourceLocation == .nas {
            scanNAS()
        }
        else {
            scanAssetsWith( .typeUserLibrary )
        }
        
    }
    
    
    @IBAction func stopButtonTouched(_ sender: UIButton) {
        scanning = false
        configureControls()
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
        startButton.isEnabled = !scanning
        stopButton .isEnabled = scanning
    }
    
    
    private func loadLabels() {
        logTrace()
        if navigatorCentral.dataSourceLocation == .device {
            deviceShareLabel.text = navigatorCentral.deviceName
            pathLabel       .text = NSLocalizedString( "Title.App", comment: "Photo Navigator" )
        }
        else {  // Must be NAS
            let descriptor = navigatorCentral.dataSourceDescriptor
            
            deviceShareLabel.text = descriptor.netbiosName + "/" + descriptor.share
            pathLabel       .text = descriptor.path
            
            currentPath = descriptor.path
        }
        
    }
    
    
    func scrollTextViewToBottom() {
        if myTextView.text.count > 0 {
            let location = myTextView.text.count - 1
            let bottom   = NSMakeRange( location, 1 )
            
            myTextView.scrollRangeToVisible( bottom )
        }
        
    }
    
    
}



// MARK: Scanning Methods

extension ScanRepoViewController {
    
    private func scanAssetsWith(_ sourceType: PHAssetSourceType ) {
        logTrace()
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            let fetchOptions = PHFetchOptions()
            
            fetchOptions.sortDescriptors = [ NSSortDescriptor( key: GlobalConstants.sortByCreationDate, ascending: true ) ]
            
            let fetchedAssets = PHAsset.fetchAssets(with: fetchOptions )
            var phAssetArray  = [PHAsset]()
            
            fetchedAssets.enumerateObjects { ( phAsset, count, stop ) in
                phAssetArray.append( phAsset )
            }
            
            phAssetArray = phAssetArray.sorted(by: { phAsset1, phAsset2 in
                phAsset1.creationDate! < phAsset2.creationDate!
            })
            
            var filteredAssetArray = [PHAsset]()
            
            for asset in phAssetArray {
                if asset.sourceType == sourceType {
                    filteredAssetArray.append( asset )
                }
                
            }
            
            for index in 0..<filteredAssetArray.count {
                myTextView.text.append( "\n" )
                myTextView.text.append( filteredAssetArray[index].descriptorString() )

//              logVerbose( "\n    %@", filteredAssetArray[index].descriptorString() )
                if index > 10 && index/20 == 0 {
                    scrollTextViewToBottom()
                }
                
            }
            
            scrollTextViewToBottom()
            navigatorCentral.populateWith( filteredAssetArray )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.presentAlert( title  :                 NSLocalizedString( "AlertTitle.ScanComplete",         comment: "Scan Complete" ),
                                   message: String( format: NSLocalizedString( "AlertMessage.ScanCompleteFormat", comment: "Added %d media files and skipped %d files." ), filteredAssetArray.count, 0 ) )
            }
            
        }
        
    }
    
    
    private func scanNAS() {
        logTrace()
        myTextView.text.append( currentPath )
        nasCentral.canSeeNasDataSourceFolders( self )
    }
    
    
    
    // MARK: NAS Scanning Utility Methods

    private func exploreNextDirectory() {
        if let directory = directoryArray.first {
            currentPath = directory.path
            
            logVerbose( "[ %@ ]", currentPath )
            
            myTextView.text.append( "\n" )
            myTextView.text.append( currentPath )
            
            nasCentral.fetchFilesAt( currentPath, self )
            directoryArray.removeFirst()
        }
        else {
            scanning = false
            configureControls()
            navigatorCentral.reloadData( self )
        }
        
    }

    
}



// MARK: NASCentralDelegate Methods

extension ScanRepoViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        
        if canSeeNasDataSourceFolders {
            nasCentral.startDataSourceSession( self )
        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error",                     comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchDirectories: Bool, _ directoryArray: [SMBFile] ) {
        logVerbose( "[ %@ ] adding [ %d ] directories to array [ %d ]", stringFor( didFetchDirectories ), directoryArray.count, self.directoryArray.count )

        if didFetchDirectories {
            self.directoryArray.append(contentsOf: directoryArray )
        }
        
        exploreNextDirectory()
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFiles: Bool, _ fileArray: [SMBFile] ) {
        logVerbose( "[ %@ ] got [ %d ]", stringFor( didFetchFiles ), fileArray.count )
        var filteredArray: [SMBFile] = []
        var directoryContents        = "\n"

        for file in fileArray {
            let fileExtension = extensionFrom( file.name )
            
            if !fileExtension.isEmpty && GlobalConstants.supportedFilenameExtensions.contains( fileExtension ) {
                filteredArray.append( file )
                
                directoryContents += "\n    "
                directoryContents.append( file.name )
            }
            else {
                numberOfFilesSkipped += 1
            }

        }
        
        directoryContents += "\n"
        
        myTextView.text.append( directoryContents )
        scrollTextViewToBottom() 
        
        navigatorCentral.addMediaFrom( filteredArray, self )
        nasCentral.fetchDirectoriesFrom( connectedShare, currentPath, self )
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didOpenShare: Bool, _ share: SMBShare) {
        logVerbose( "[ %@ ]", stringFor( didOpenShare ) )

        if didOpenShare {
            navigatorCentral.deleteAllMediaData( self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession: Bool, share: SMBShare ) {
        logVerbose( "[ %@ ]", stringFor( didStartDataSourceSession ) )

        if didStartDataSourceSession {
            connectedShare = share
            nasCentral.openShare( share, self )
        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error",                  comment: "Error" ),
                          message: NSLocalizedString( "AlertMessage.UnableToStartSession", comment: "Unable to start a session with the selected share!" ) )
        }
        
    }
    
    
}



// MARK: NavigatorCentralDelegate Methods

extension ScanRepoViewController: NavigatorCentralDelegate {
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didAddMedia: Bool, count: Int ) {
        logVerbose( "[ %@ ] [ %d ]", stringFor( didAddMedia ), count )
        
        if didAddMedia {
            numberOfMediaAdded += count
        }
        else {
            presentAlert(title  : NSLocalizedString( "AlertTitle.Error",              comment: "Error!" ),
                         message: NSLocalizedString( "AlertMessage.UnableToAddMedia", comment: "We are unable to add the media files that we found!  Please try again." ) )
        }

    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didDeleteMediaData: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didDeleteMediaData ) )
        
        if didDeleteMediaData {
            nasCentral.fetchFilesAt( currentPath, self )
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.UnableToDeleteMedia",       comment: "Delete Failed!" ),
                                   message: NSLocalizedString( "AlertMessage.UnableToDeleteMediaRefs", comment: "We were unable to delete all the media references from our database!  This may have left unwanted references in your database." ) )
            }
        }

    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadMediaData: Bool ) {
        logVerbose( "loaded [ %d ] media files", navigatorCentral.numberOfMediaFilesLoaded )
        
        if !scanning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.presentAlert( title  :                 NSLocalizedString( "AlertTitle.ScanComplete",         comment: "Scan Complete" ),
                                   message: String( format: NSLocalizedString( "AlertMessage.ScanCompleteFormat", comment: "Added %d media files and skipped %d files." ), self.numberOfMediaAdded, self.numberOfFilesSkipped ) )
            }

        }

    }


}


