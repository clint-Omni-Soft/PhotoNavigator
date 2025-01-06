//
//  SettingsViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/7/24.
//

import UIKit



class SettingsViewController: UIViewController {

    
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTableView        : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct CellIndexes {
        static let about              = 0
        static let displaySettings    = 1
        static let howToUse           = 2
        static let mediaRepository    = 3
        static let scanRepository     = 4
        static let deviceName         = 5
        static let testing            = 6        // Testing
    }
    

    private struct Constants {
        static let cellID = "SettingsTableViewCell"
    }
    
    private struct StoryboardIds {
        static let about             = "AboutViewController"
        static let displaySettings   = "DisplaySettingsViewController"
        static let howToUse          = "HowToUseViewController"
        static let nasDriveSelector  = "NasDriveSelectorViewController"
        static let mediaLocation     = "MediaLocationViewController"
        static let scanRepo          = "ScanRepoViewController"
        static let testing           = "TestingViewController"     // Testing
    }
    
    private var canSeeNasFolders    = false
    private var navigatorCentral    = NavigatorCentral.sharedInstance
    private var notificationCenter  = NotificationCenter.default
    private var optionArray         = [ NSLocalizedString( "Title.About",               comment: "About"                 ),
                                        NSLocalizedString( "Title.DisplaySettings",     comment: "Display Settings"      ),
                                        NSLocalizedString( "Title.HowToUse",            comment: "How to Use"            ),
                                        NSLocalizedString( "Title.MediaRepository",     comment: "Media Repository"      ),
                                        NSLocalizedString( "Title.ScanMediaRepository", comment: "Scan Media Repository" ) ]
    private var showHowToUse        = true
    private let userDefaults        = UserDefaults.standard


    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.Settings", comment: "Settings" )
        
        if navigatorCentral.dataStoreLocation != .device {
            optionArray.append( NSLocalizedString( "Title.UserAssignedDeviceName", comment: "User Assigned Device Name" ) )
        }

        if runningInSimulator() {   // Testing
            optionArray.append( "Testing" )
        }
        
        if let _ = userDefaults.string(forKey: UserDefaultKeys.howToUseShown ) {
            showHowToUse = false
        }
        else {
            userDefaults.set( UserDefaultKeys.howToUseShown, forKey: UserDefaultKeys.howToUseShown )
        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        if !navigatorCentral.stayOffline && ( navigatorCentral.dataStoreLocation == .nas || navigatorCentral.dataStoreLocation == .shareNas ) {
            canSeeNasFolders = false
            NASCentral.sharedInstance.canSeeNasFolders( self )

            myActivityIndicator.isHidden = false
            myActivityIndicator.startAnimating()
        }
        else {
            myActivityIndicator.isHidden = true
            myActivityIndicator.stopAnimating()
        }
        
        loadBarButtonItems()
        registerForNotifications()
        
        if showHowToUse {
            showHowToUse = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.launchHowToUseViewController()
            }
            
        }
        else if navigatorCentral.dataStoreLocation != .device && !flagIsPresentInUserDefaults( UserDefaultKeys.deviceName ) {
            presentAlert( title:   NSLocalizedString( "AlertTitle.DeviceNameRequired",   comment: "Device Name is Required for NAS" ),
                          message: NSLocalizedString( "AlertMessage.DeviceNameRequired", comment: "Please go to the Settings tab, tap on the 'User Assigned Device Name' entry in the table and enter a name for this device." ) )
        }

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        
        notificationCenter.removeObserver( self )
    }
    

    
    // MARK: NSNotification Methods
    
    @objc func deviceNameNotSet( notification: NSNotification ) {
        logTrace()
        promptForDeviceName()
    }
    
    
    @objc func repoScanRequested( notification: NSNotification ) {
        logTrace()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
            self.launchScanRepoViewController()
        }
        
    }
    
    

    // MARK: Target/Action Methods
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let     message = String( format: NSLocalizedString( "AlertMessage.SelectHowToUseForInfo", comment: "Select '%@' for helpful information on '%@' and '%@'." ),
                                          NSLocalizedString( "Title.HowToUse",                     comment: "How to Use"            ),
                                          NSLocalizedString( "Title.MediaRepository",              comment: "Media Repository"      ),
                                          NSLocalizedString( "Title.ScanMediaRepository",          comment: "Scan Media Repository" ) )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }
    
    

    // MARK: Utility Methods

    private func loadBarButtonItems() {
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad {
            configureBackBarButtonItem()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) )
    }
    
    
    private func registerForNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( deviceNameNotSet(  notification: ) ), name: NSNotification.Name( rawValue: Notifications.deviceNameNotSet  ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( repoScanRequested( notification: ) ), name: NSNotification.Name( rawValue: Notifications.repoScanRequested ), object: nil )
    }
    
}



// MARK: NASCentral Delegate Methods

extension SettingsViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )
        
        self.canSeeNasFolders = canSeeNasFolders
        
        myActivityIndicator.stopAnimating()
        myActivityIndicator.isHidden = true
    }

    
}



// MARK: UITableViewDataSource Methods

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        cell.textLabel?.text = optionArray[indexPath.row]
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logTrace()
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch indexPath.row  {
        case CellIndexes.about:                 launchAboutViewController()
        case CellIndexes.deviceName:            promptForDeviceName()
        case CellIndexes.displaySettings:       launchDisplaySettingsViewController()
        case CellIndexes.howToUse:              launchHowToUseViewController()
        case CellIndexes.mediaRepository:       launchMediaLocationViewController()
        case CellIndexes.scanRepository:        launchScanRepoViewController()
        case CellIndexes.testing:               launchTestingViewController()
        default:                                break
        }
        
    }
    

    
    // MARK: UITableViewDelegate Utility Methods
 
    private func launchAboutViewController() {
        guard let aboutVC: AboutViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.about ) as? AboutViewController else {
            logTrace( "Error!  Unable to load AboutViewController!" )
            return
        }
        
        logTrace()
        navigationController?.pushViewController( aboutVC, animated: true )
    }
    
    
    private func launchDisplaySettingsViewController() {
        guard let displaySettingsVC: DisplaySettingsViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.displaySettings ) as? DisplaySettingsViewController else {
            logTrace( "Error!  Unable to load DisplaySettingsViewController!" )
            return
        }

        logTrace()
        navigationController?.pushViewController( displaySettingsVC, animated: true )
    }
    
    
    private func launchHowToUseViewController() {
        guard let howToUseVC: HowToUseViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.howToUse ) as? HowToUseViewController else {
            logTrace( "Error!  Unable to load HowToUseViewController!" )
            return
        }

        logTrace()
        navigationController?.pushViewController( howToUseVC, animated: true )
    }
    
    
    private func launchMediaLocationViewController() {
        guard let mediaLocationVC: MediaLocationViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.mediaLocation ) as? MediaLocationViewController else {
            logTrace( "Error!  Unable to load MediaLocationViewController!" )
            return
        }

        logTrace()
        navigationController?.pushViewController( mediaLocationVC, animated: true )
    }
    
    
    private func launchScanRepoViewController() {
        if navigatorCentral.dataSourceLocation == .notAssigned {
            presentAlert( title  : NSLocalizedString( "AlertTitle.MediaRepoNotSet",   comment: "The Media Repository has NOT been set yet!" ),
                          message: NSLocalizedString( "AlertMessage.MediaRepoNotSet", comment: "Select using the Media Repository option" ) )
        }
        else {
            guard let scanRepoVC: ScanRepoViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.scanRepo ) as? ScanRepoViewController else {
                logTrace( "Error!  Unable to load ScanRepoViewController!" )
                return
            }

            logTrace()
            navigationController?.pushViewController( scanRepoVC, animated: true )
        }

    }
    
    
    private func launchTestingViewController() {
        logTrace()
//        guard let testingVC: TestingViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.testing ) as? TestingViewController else {
//            logTrace( "Error!  Unable to load TestingViewController!" )
//            return
//        }
//
//        navigationController?.pushViewController( testingVC, animated: true )
    }
    

    private func promptForDeviceName() {
        let     alert = UIAlertController.init(title: NSLocalizedString( "AlertTitle.EnterDeviceName", comment: "Enter Device Name" ), message: "", preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            let     deviceNameTextField = alert.textFields![0] as UITextField
            
            if let textString = deviceNameTextField.text {
                
                if !textString.isEmpty {
                    if textString == self.navigatorCentral.deviceName {
                        logTrace( "No change ... do nothing" )
                    }
                    else {
                        logTrace( "We have a new name" )
                        self.navigatorCentral.deviceName = textString
                    }

                }
                else {
                    logTrace( "We got an empty string" )
                }
                
            }
            else {
                logTrace( "We didn't get anything" )
            }

        }

        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addTextField
            { ( textField ) in
                textField.autocapitalizationType = .words
                textField.placeholder            = NSLocalizedString( "LabelText.NotSet", comment: "Not Set" )
                textField.text                   = self.navigatorCentral.deviceName
            }
        
        alert.addAction( okAction )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                var presentAgain = false
                
                // Keep after them until they provide a name
                if let deviceNameString = self.userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
                    presentAgain = deviceNameString.isEmpty || deviceNameString.count == 0
                }
                else {
                    presentAgain = true
                }
                
                if presentAgain {
                    self.promptForDeviceName()
                }
                
            }
            
        })
        
    }
    
    
}

