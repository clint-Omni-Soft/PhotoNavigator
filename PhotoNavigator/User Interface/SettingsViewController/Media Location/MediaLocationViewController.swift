//
//  MediaLocationViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 5/6/24.
//

import UIKit
import Photos


class MediaLocationViewController: UIViewController {
   
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTableView        : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct CellIDs {
        static let basic  = "MediaLocationViewControllerCell"
        static let detail = "MediaLocationViewControllerDetailCell"
    }
    
    private struct CellIndexes {
        static let device = 0
        static let nas    = 2
        static let unused = 3
    }
    
    private struct StoryboardIds {
        static let nasSelector = "NasDriveSelectorViewController"
    }
    
    private var canSeeCloud                 = false
    private var canSeeNasDataSourceFolders  = false
    private var canSeeCount                 = 0
    private let cloudCentral                = CloudCentral.sharedInstance
    private let nasCentral                  = NASCentral.sharedInstance
    private var navigatorCentral            = NavigatorCentral.sharedInstance
    private var notificationCenter          = NotificationCenter.default
    private var selectedOption              = CellIndexes.device
    private var userDefaults                = UserDefaults.standard
    
    private let optionArray = [ NSLocalizedString( "Title.Device",     comment: "Device" ),
                                NSLocalizedString( "Title.InNASDrive", comment: "Network Accessible Storage" ) ]
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        if navigatorCentral.pleaseWaiting {
            logTrace( "PleaseWaiting..." )
            return
        }
        
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.MediaRepository",  comment: "Media Repository" )
        
        switch navigatorCentral.dataSourceLocation {
            case .device:      selectedOption = CellIndexes.device
            case .nas:         selectedOption = CellIndexes.nas
            case .shareNas:    selectedOption = CellIndexes.nas
            default:           logTrace( "ERROR!  SBH!" )
        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        canSeeCount = 1
        canSeeCloud = false
        canSeeNasDataSourceFolders = false
        
        cloudCentral.canSeeCloud( self )
        nasCentral.canSeeNasDataSourceFolders( self )

        if selectedOption == CellIndexes.device  {
            PHPhotoLibrary.requestAuthorization(for: .readWrite ) { (status) in
                if PHPhotoLibrary.authorizationStatus() != .authorized {
                    self.presentAlert( title  : NSLocalizedString( "AlertTitle.AuthorizationRequired",      comment: "Authorization Required!" ),
                                       message: NSLocalizedString( "AlertMessage.PhotoLibraryNotAuthorized", comment: "This app requires your authorization to access the photo library on this device.  Please update Settings to allow us to view your photos." ) )
                }
                
            }
            
        }
        else {
            myActivityIndicator.isHidden = false
            myActivityIndicator.startAnimating()
        }
        
        loadBarButtonItems()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let    message = NSLocalizedString( "InfoText.MediaRepository",  comment: "Use this utility to specify where your photos and media files are located.  They can be on either (a) on this device or (b) on a Network Accessible Storage (NAS) unit.\n\nThis app ONLY recognizes photos and media files in the following file formats: JPG, JPEG, PNG, MPG, MPEG or MOV." )

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        configureBackBarButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) )
    }
    

}



// MARK: CloudCentralDelegate Methods

extension MediaLocationViewController: CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        self.canSeeCloud = canSeeCloud

        if canSeeCloud {
            canSeeCount += 1
            
            if canSeeCount > 1 {
                myActivityIndicator.stopAnimating()
                myActivityIndicator.isHidden = true
            }

            myTableView.reloadData()
        }

    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool ) {
        logVerbose( "[ %@ ]", stringFor( rootDirectoryIsPresent ) )
//        promptToScanNow()
    }

}



// MARK: NASCentralDelegate Methods

extension MediaLocationViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        
        self.canSeeNasDataSourceFolders = canSeeNasDataSourceFolders
        canSeeCount += 1
        
        if canSeeCount > 1 {
            myActivityIndicator.stopAnimating()
            myActivityIndicator.isHidden = true
        }

        myTableView.reloadData()
    }

    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension MediaLocationViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension MediaLocationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     useDetailCell = ( indexPath.row == CellIndexes.nas ) && canSeeNasDataSourceFolders && ( selectedOption == CellIndexes.nas )
        let     cellID        = useDetailCell ? CellIDs.detail : CellIDs.basic
        
        guard let cell = tableView.dequeueReusableCell( withIdentifier: cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }

        cell.textLabel?.text = optionArray[indexPath.row]
        cell.accessoryType   = ( indexPath.row == selectedOption ) ? .checkmark : .none
        
        if useDetailCell {
            let     descriptor = navigatorCentral.dataSourceDescriptor
            let     fullPath   = String( format: "%@/%@/%@", descriptor.netbiosName, descriptor.share, descriptor.path )
            
            cell.detailTextLabel?.text = fullPath
        }
        else {
            cell.backgroundColor = .white
        }
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension MediaLocationViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow( at: indexPath, animated: false )
        
        if  indexPath.row == selectedOption && indexPath.row != CellIndexes.nas {
            return
        }
        
        switch indexPath.row {
        case CellIndexes.device:
            selectedOption = CellIndexes.device
            navigatorCentral.dataSourceLocation = .device
            tableView.reloadData()
            promptToScanNow()

        case CellIndexes.nas:
            if canSeeNasDataSourceFolders {
                launchNasSelectorViewController()
            }
            else {
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                     comment:  "Error" ),
                              message : NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
            }

        default:
            logTrace( "ERROR!  SBH!" )
        }
        
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods
    
    private func launchNasSelectorViewController() {
        guard let nasDriveSelector: NasDriveSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.nasSelector ) as? NasDriveSelectorViewController else {
            logTrace( "Error!  Unable to load NasDriveSelectorViewController!" )
            return
        }
        
        logTrace()
        nasDriveSelector.mode = .dataSourceLocation
        navigationController?.pushViewController( nasDriveSelector, animated: true )
    }
    
    
    private func promptToScanNow() {
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ScanNowPrompt", comment: "Would you like for us to scan your repository now?" ), message: "", preferredStyle : .alert)
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .default )
        { ( alertAction ) in
            logTrace( "Yes Action" )
            if let settingsViewController = self.navigationController?.viewControllers[1] {
                self.navigationController?.popToViewController( settingsViewController, animated: true)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.repoScanRequested ), object: self )
            }
            
        }

        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No" ), style: .default )
        { ( alertAction ) in
            logTrace( "No Action" )
            if let settingsViewController = self.navigationController?.viewControllers[1] {
                self.navigationController?.popToViewController( settingsViewController, animated: true)
            }
            
        }

        alert.addAction( yesAction )
        alert.addAction( noAction  )

        present( alert, animated: true, completion: nil )
    }
    
    

}
