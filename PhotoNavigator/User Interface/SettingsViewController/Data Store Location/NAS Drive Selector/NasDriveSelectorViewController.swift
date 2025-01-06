//
//  NasDriveSelectorViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/8/24.
//


import UIKit


class NasDriveSelectorViewController: UIViewController {

    enum NasDriveSelectorMode {
        case dataSourceLocation
        case dataStoreLocation
    }
    
    
    // MARK: Public Variables
    
    var mode: NasDriveSelectorMode = .dataStoreLocation
    
    @IBOutlet weak var activityIndicator                : UIActivityIndicatorView!
    @IBOutlet weak var controlPanelCreateHereButton     : UIButton!
    @IBOutlet weak var controlPanelHeightConstraint     : NSLayoutConstraint!
    @IBOutlet weak var controlPanelPathLabel            : UILabel!
    @IBOutlet weak var controlPanelTitleLabel           : UILabel!
    @IBOutlet weak var controlPanelUpOneLevelButton     : UIButton!
    @IBOutlet weak var myTableView                      : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct CellIDs {
        static let basic    = "NasDriveSelectorViewControllerCell"
        static let subtitle = "NasDriveSelectorViewControllerSubtitleCell"
    }

    private struct Constants {
        static let constraintMaxHeight : CGFloat      = 100.0
        static let scanTime            : TimeInterval = 3
    }
    
    private enum ControlPanelStates {
        case hiddenState
        case saveHereState
    }
    
    private enum DirectoryCreationStates {
        case targetCreate
        case picturesCreate
        case done
    }

    private enum StateMachine {
        case deviceSelect
        case shareSelect
        case navigating
    }
    
    private struct StoryboardIds {
        static let nasLogin         = "NasLoginViewController"
        static let picker           = "PickerViewController"
        static let transferProgress = "TransferProgressViewController"
    }
    
    private var actionButtonState         : ControlPanelStates = .hiddenState
    private var directoryCreateState      = DirectoryCreationStates.done
    private var currentState              : StateMachine = .deviceSelect
    private var deviceArray               : [SMBDevice] = []
    private var devicePassword            = ""
    private var deviceUserName            = ""
    private var navigatorCentral          = NavigatorCentral.sharedInstance
    private var nasCentral                = NASCentral.sharedInstance
    private var notificationCenter        = NotificationCenter.default
    private var openShare                 : SMBShare!
    private var originalDataStoreLocation = NavigatorCentral.sharedInstance.dataStoreLocation
    private var pathsOnShare              : [String] = []
    private var questionBarButtonItem     : UIBarButtonItem!
    private var selectedDevice            : SMBDevice!
    private var selectedShare             : SMBShare!
    private var selectionMade             = false
    private var shareArray                : [SMBShare] = []
    private var tableDataArray            : [String]   = []
    private var targetDirectoryIndex      = GlobalConstants.noSelection
    private var upBarButtonItem           : UIBarButtonItem!
    

    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem              .title   = NSLocalizedString( "Title.SelectNASDrive",   comment: "Select NAS Drive" )
        controlPanelTitleLabel      .text    = NSLocalizedString( "LabelText.NetworkPath",  comment: "Network Path"     )
        controlPanelCreateHereButton.setTitle( NSLocalizedString( "ButtonTitle.CreateHere", comment: "Create Here"      ), for: .normal )
        
        configureBackBarButtonItem()
        configureControlPanelButtonsFor( .hiddenState )
        controlPanelHeightConstraint.constant = 0.0

        nasCentral.fetchConnectedDevices( self )
            
        showActivityIndicator( true )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        questionBarButtonItem = UIBarButtonItem.init( image : UIImage(named: "question"  ), style : .plain, target : self, action : #selector( questionBarButtonTouched(_:) ) )
        upBarButtonItem       = UIBarButtonItem.init( image : UIImage(named: "upOneLevel"), style : .plain, target : self, action : #selector( upBarButtonItemTouched(_:)   ) )
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func upBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        // This button is only visible when we can transition from shares to devices
        displayDevices()
    }
    
    
    @IBAction func controlPanelCreateHereButtonTouched(_ sender: UIButton ) {
        logTrace()
        if mode == .dataStoreLocation {
            startTransitionToNas( shared: false )
        }
        
    }

    
    @IBAction func controlPanelUpOneLevelButtonTouched(_ sender: UIButton) {
//        logTrace()
        configureControlPanelButtonsFor( .hiddenState )
        
        if currentState == .navigating {
            if pathsOnShare.count == 0 {
                currentState = .shareSelect
                loadShares()
            }
            else {
                pathsOnShare.removeLast()
                configureControlPanelButtonsFor( .hiddenState )
                showActivityIndicator( true )
                
                nasCentral.fetchDirectoriesFrom( selectedShare, currentPath(), self )
            }

        }
        else {
            if currentState == .shareSelect {
                currentState = .deviceSelect
                loadDevices()
            }
            
        }

    }
    
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        var     message = "Unknown"
        
        switch mode {
        case .dataSourceLocation:   message = NSLocalizedString( "InfoText.MediaRepository",   comment: "Use this utility to specify where your photos and media files are located.  They can be on either (a) on this device or (b) on a Network Accessible Storage (NAS) unit.\n\nThis app ONLY recognizes photos and media files in the following file formats: JPG, JPEG, PNG, MPG, MPEG or MOV." )
        case .dataStoreLocation:    message = NSLocalizedString( "InfoText.DataStoreLocation", comment: "This app gives you the option to store your data either on...\n\n   (a) on your device (default) or\n   (b) on a Network Accessible Storage (NAS) drive. \n\nThe key point here is that there is no sharing on the device. If you prefer to use a NAS then anyone who has this app and access to your Wi-Fi can access your data." )
        }

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    

    // MARK: Utility Methods
    
    private func configureControlPanelButtonsFor(_ state : ControlPanelStates ) {
        actionButtonState = state
        controlPanelCreateHereButton.isHidden = ( state == .hiddenState ) || mode == .dataSourceLocation
        controlPanelUpOneLevelButton.isHidden = ( currentState != .navigating ) // We only use the barButtonItem for going from share to device
    }


    private func currentPath() -> String {
        var     path = ""
        
        for subPath in pathsOnShare {
            if path.isEmpty {
                path = subPath
            }
            else {
                path = path + "/" + subPath
            }

        }
        
        return path
    }
    
    
    private func currentStateName() -> String {
        var name = "Unknown"
        
        switch currentState {
        case .deviceSelect:     name = "deviceSelect"
        case .shareSelect:      name = "shareSelect"
        case .navigating:       name = "navigating"
        }
        
        return name
    }
    
    
    private func displayDevices() {
        logTrace()
        showActivityIndicator( false )
        currentState = .deviceSelect
        loadDevices()

        nasCentral.closeShareAndDevice( self )
    }
    
    
    private func hideUpBarButtonItem(_ hide : Bool ) {
        // The upBarButtonItem is only used for transitioning between shares and devices
        navigationItem.rightBarButtonItems = hide ? [questionBarButtonItem] : [upBarButtonItem, questionBarButtonItem]
    }
    
    
    private func launchTransferProgressViewController() {

        guard let transferProgressVC : TransferProgressViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.transferProgress ) as? TransferProgressViewController else {
            logTrace( "Error!  Unable to load TransferProgressViewController!" )
            return
        }

        transferProgressVC.modalPresentationStyle = .overFullScreen
        
        transferProgressVC.popoverPresentationController?.delegate                 = self
        transferProgressVC.popoverPresentationController?.permittedArrowDirections = .any
        transferProgressVC.popoverPresentationController?.sourceRect               = view.frame
        transferProgressVC.popoverPresentationController?.sourceView               = view
        
        present( transferProgressVC, animated: true, completion: nil )
    }
    
    
    private func loadDevices() {
        navigationItem.title = NSLocalizedString( "Title.SelectNASDrive", comment: "Select NAS Drive" )
        tableDataArray.removeAll()
        
        for device in deviceArray {
            tableDataArray.append( device.netbiosName )
        }
        
        DispatchQueue.main.asyncAfter( deadline: .now() + 0.1 ) {
            self.hideUpBarButtonItem( true )
            self.controlPanelHeightConstraint.constant = 0.0
            
            self.myTableView.reloadData()
        }
        
    }
    

    private func loadShares() {
       navigationItem.title = NSLocalizedString( "Title.SelectShare", comment: "Select a Share" )
       tableDataArray.removeAll()
        
        for share in shareArray {
            tableDataArray.append( share.name )
        }
        
        DispatchQueue.main.asyncAfter( deadline: .now(), execute: {
            self.hideUpBarButtonItem( false )
            self.controlPanelHeightConstraint.constant = 0.0
            self.myTableView.reloadData()
        } )
        
    }
    
    
    private func presentConfirmationForMoveToNas() {
        logTrace()
        var     message = NSLocalizedString( "AlertMessage.DataWillBeMovedTo", comment: "When you hit the OK button we will transfer your data then kill the app.  When you re-start the app your data will stored be on your " )
        let     title   = NSLocalizedString( "Title.DataStoreLocation",        comment: "Data Store Location" )
        
        message += NSLocalizedString( "Title.InNASDrive", comment: "Network Assessible Storage" ) + "\n\n" + textForControlPanelPath()
        
        let     alert = UIAlertController.init( title : title, message : message, preferredStyle : .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action ... starting transfer to NAS" )
            self.selectionMade = true
            self.launchTransferProgressViewController()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel ) 
        { ( alertAction ) in
            logTrace( "Cancel Action" )
            self.resetSelection()
        }

        alert.addAction( okAction     )
        alert.addAction( cancelAction )

        present( alert, animated: true, completion: nil )
    }
    
    
    private func presentConfirmationForNasSharing() {
        logTrace()
        var     message = NSLocalizedString( "AlertMessage.DataWillBeShared", comment: "When you hit the OK button we will transfer your data then kill the app.  When you re-start the app will SHARE the data in your " )
        let     title   = NSLocalizedString( "Title.DataStoreLocation",       comment: "Data Store Location" )
        
        message += NSLocalizedString( "Title.InNASDrive", comment: "Network Assessible Storage" ) + "\n\n" + textForControlPanelPath()
        
        let     alert = UIAlertController.init( title : title, message : message, preferredStyle : .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action ... starting transfer to DEVICE" )
            self.selectionMade = true
            self.launchTransferProgressViewController()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
            self.resetSelection()
        }

        alert.addAction( okAction     )
        alert.addAction( cancelAction )

        present( alert, animated: true, completion: nil )
    }
    
    
    private func resetSelection() {
        self.directoryCreateState = .done
        self.targetDirectoryIndex = GlobalConstants.noSelection
        
        self.navigatorCentral.dataStoreLocation = self.originalDataStoreLocation
        
        self.pathsOnShare.removeLast()
    }
    
    
    private func saveExportedCsvFile() {
        logTrace()
        let     fileManager = FileManager.default
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     exportedCsvFileUrl = documentDirectoryURL.appendingPathComponent( Filenames.exportedCsv )
            
            if FileManager.default.fileExists(atPath: exportedCsvFileUrl.path ) {
                if let exportedCsvFileData = FileManager.default.contents( atPath: exportedCsvFileUrl.path ) {
                    let     fullPath = self.currentPath() + "/" + Filenames.exportedCsv
                    
                    // An alert will be shown when this completes
                    nasCentral.saveData( exportedCsvFileData, selectedShare, fullPath, self )
                }
                else {
                    logTrace( "ERROR!  Unable to read CSV file!" )
                }

            }
            else {
                logTrace( "ERROR!  CSV file does not exist!" )
            }

        }
        else {
            logTrace( "ERROR!  Unable to extract documentDirectoryURL!" )
        }
        
    }
    
    
    private func showActivityIndicator(_ show : Bool ) {
        activityIndicator.isHidden = !show
        
        if show {
            activityIndicator.startAnimating()
        }
        else {
            activityIndicator.stopAnimating()
        }

    }
    
    
    private func startTransitionToNas( shared: Bool ) {
        logVerbose( "[ %@ ]", stringFor( shared ) )
        navigatorCentral.dataStoreLocation = ( shared ? .shareNas : .nas )
        
        configureControlPanelButtonsFor( .hiddenState )

        if shared {
            pathsOnShare.append( DirectoryNames.root )
            nasCentral.saveDataStoreAccessKey( currentPath(), self )
        }
        else {
            directoryCreateState = .targetCreate
            pathsOnShare.append( DirectoryNames.root )
            
            nasCentral.createDirectoryOn( selectedShare, currentPath(), self )
        }
        
    }


    private func textForControlPanelPath() -> String {
        var     path : String = selectedDevice.netbiosName
        
        if currentState == .navigating {
            path += "/" + selectedShare.name
            
            let     navigation = currentPath()
            
            if !navigation.isEmpty {
                path += "/" + navigation
            }
            
        }
        
        return path
    }
    

}



// MARK: NASCentralDelegate Access Methods

extension NasDriveSelectorViewController : NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, didCloseShareAndDevice: Bool) {
        logVerbose( "[ %@ ]", stringFor( didCloseShareAndDevice ))
        
        showActivityIndicator( false )
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didConnectToDevice: Bool, _ device: SMBDevice ) {
        if didConnectToDevice {
            logVerbose( "[ %@ ]", stringFor( didConnectToDevice ) )
            saveDeviceCredentials()
            currentState = .shareSelect
            
            nasCentral.fetchShares( self )
        }
        else {
            removeDeviceCredentials()
            currentState = .deviceSelect

            showActivityIndicator( false )
            
            logVerbose( "\n    Connect failed using credentials for [ %@ ] = [ %@ ]/[ %@ ]", selectedDevice.netbiosName, deviceUserName, devicePassword )
            DispatchQueue.main.asyncAfter( deadline: .now() ) {
                self.presentAlert( title   : NSLocalizedString( "AlertTitle.Error",      comment: "Error!" ),
                                   message : NSLocalizedString( "AlertMessage.NoAccess", comment: "Unable to access this file server!" ) )
            }
            
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didCreateDirectory: Bool) {
        if didCreateDirectory {
            if directoryCreateState == .targetCreate {
                logVerbose( "Created %@ Directory", DirectoryNames.root )
                let     path = currentPath() + "/" + DirectoryNames.pictures
                
                directoryCreateState = .picturesCreate
                nasCentral.createDirectoryOn( selectedShare, path, self )
            }
            else {
                logVerbose( "Created %@ Directory", DirectoryNames.pictures )
                directoryCreateState = .done
                
                nasCentral.saveDataStoreAccessKey( currentPath(), self )
            }

        }
        else {
            navigatorCentral.dataStoreLocation = .device
            displayDevices()
            
            logVerbose( "ERROR!  We failed to create the %@ directory!", ( directoryCreateState == .targetCreate ) ? DirectoryNames.root : DirectoryNames.pictures )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",            comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.UnableToCreate", comment: "Unable to create our directory!" ) )
        }

    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchDevices: Bool, _ deviceArray: [SMBDevice] ) {
        logVerbose( "[ %@ ]  deviceArray[ %d ]", stringFor( didFetchDevices ), deviceArray.count )
        
        showActivityIndicator( false )

        let networkAccessGranted = flagIsPresentInUserDefaults( UserDefaultKeys.networkAccessGranted )
        
        // This will only happen 1 time when the OS asks for permission for us to access devices on your network
       if didFetchDevices && deviceArray.count == 0 && !networkAccessGranted {
           saveFlagInUserDefaults( UserDefaultKeys.networkAccessGranted )
           navigationController?.popViewController(animated: true )
        }
        
        if didFetchDevices {
            self.deviceArray = deviceArray
            loadDevices()
        }
        else {
            logTrace( "ERROR!  Unable to fetch devices" )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                  comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.UnableToFetchDevices", comment: "Unable to fetch devices!" ) )
        }

    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchDirectories: Bool, _ directoryArray: [SMBFile] ) {
        logVerbose( "didFetchDirectories[ %@ ]  count[ %d ]", stringFor( didFetchDirectories ), directoryArray.count )
        targetDirectoryIndex = GlobalConstants.noSelection

        showActivityIndicator( false )

        if !didFetchDirectories {
            configureControlPanelButtonsFor( .hiddenState )
        }
        else {
            tableDataArray.removeAll()
            
            for index in 0..<directoryArray.count {
                let     directory = directoryArray[index]
                
                tableDataArray.append( directory.name )

                if directory.name == DirectoryNames.root {
                    targetDirectoryIndex = index
                }

            }
            
            DispatchQueue.main.asyncAfter( deadline: .now() ) {
                self.navigationItem.title = NSLocalizedString( "Title.SelectDirectory", comment: "Select Directory" )
                
                self.controlPanelHeightConstraint.constant = Constants.constraintMaxHeight
                self.controlPanelPathLabel       .text     = self.textForControlPanelPath()
                
                var     isHidden = true
                
                switch self.mode {
                case .dataSourceLocation:    isHidden = false   // We don't have a target directory in this mode ... it's whatever directory you choose
                case .dataStoreLocation:     isHidden = self.targetDirectoryIndex != GlobalConstants.noSelection
                }

                self.configureControlPanelButtonsFor( isHidden  ? .hiddenState : .saveHereState )
                self.hideUpBarButtonItem( true )    // We don't show this button when we are navigating inside a share, only when we want to transition from a share to the device
                
                self.myTableView.reloadData()
                
                if ( self.mode == .dataStoreLocation ) && ( self.targetDirectoryIndex != GlobalConstants.noSelection ) {
                    self.startTransitionToNas( shared: true )
                    self.presentConfirmationForNasSharing()
                }
                
            }
            
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFile: Bool, _ data: Data) {
        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchShares : Bool, _ shareArray : [SMBShare] ) {
        targetDirectoryIndex = GlobalConstants.noSelection
        
        showActivityIndicator( false )

        if didFetchShares && !shareArray.isEmpty {
            logVerbose( "[ %@ ]", stringFor( didFetchShares ) )
            self.shareArray = shareArray
            loadShares()
        }
        else {
            logVerbose( "[ %@ ]  shareArray.isEmpty[ %@ ]", stringFor( didFetchShares ), stringFor( shareArray.isEmpty ) )
            displayDevices()
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error",             comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.NoSharesOnDrive", comment: "There are no shares available on this drive!" ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didOpenShare: Bool, _ share: SMBShare) {
        logVerbose( "[ %@ ]", stringFor( didOpenShare ) )

        if didOpenShare {
            openShare = share
            nasCentral.returnCsvFiles = false      // This is passed through to SMBCentral
            nasCentral.fetchDirectoriesFrom( selectedShare, currentPath(), self )
        }
        else {
            displayDevices()
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.UnableToOpenShare", comment: "Unable to open the selected share!" ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didSaveDataSourceAccessKey: Bool) {
        logVerbose( "[ %@ ]", stringFor( didSaveDataSourceAccessKey ) )
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didSaveDataStoreAccessKey: Bool) {
        logTrace()
        if navigatorCentral.dataStoreLocation == .nas {
            navigatorCentral.createLastUpdatedFile()
            presentConfirmationForMoveToNas()
        }
        else if navigatorCentral.dataStoreLocation == .shareNas {
            presentConfirmationForNasSharing()
        }

//        nasCentral.closeShareAndDevice( self )
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didSaveData: Bool) {
        logVerbose( "didSaveData[ %@ ]", stringFor(didSaveData) )
    }
    
    

    // MARK: NASCentralDelegate Discovery Utility Methods
    
    private func removeDeviceCredentials() {
        UserDefaults.standard.removeObject( forKey: selectedDevice.netbiosName )
        UserDefaults.standard.synchronize()
    }
    
    
    private func saveDeviceCredentials() {
        let     userNamePassword = deviceUserName + "/" + devicePassword
        
        UserDefaults.standard.set( userNamePassword, forKey: selectedDevice.netbiosName )
        UserDefaults.standard.synchronize()
    }


}



// MARK: NasLoginViewControllerDelegate Methods

extension NasDriveSelectorViewController : NasLoginViewControllerDelegate {
    
    func nasLoginViewController(_ nasLoginViewController: NasLoginViewController, didAccept userName: String, and password: String ) {
        selectedDevice = nasLoginViewController.device!
        devicePassword = password
        deviceUserName = userName
        
        showActivityIndicator( true )

        nasCentral.connectTo( selectedDevice, userName, password, self )
    }
    
    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension NasDriveSelectorViewController : UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension NasDriveSelectorViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableDataArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     title           = tableDataArray[indexPath.row]
        let     useDeviceCell   = ( mode == .dataStoreLocation ) && ( currentState == .deviceSelect ) && ( title == nasCentral.dataStoreAccessKey.netbiosName )
        let     cellID          = useDeviceCell ? CellIDs.subtitle : CellIDs.basic
        let     cell            = tableView.dequeueReusableCell(withIdentifier: cellID ) ?? UITableViewCell.init()

        cell.accessoryType   = ( mode != .dataStoreLocation ) ? .none : ( currentState == .navigating ) && ( indexPath.row == targetDirectoryIndex ) ? .checkmark : .none
        cell.textLabel?.text = title
        
        if useDeviceCell {
            let accessKey = ( mode == .dataStoreLocation ) ? nasCentral.dataStoreAccessKey : nasCentral.dataSourceAccessKey
            
            cell.accessoryType         = .checkmark
            cell.detailTextLabel?.text = String( format: "%@/%@", accessKey.netbiosName, accessKey.path )
        }
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension NasDriveSelectorViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch currentState {
        case .deviceSelect:     selectedDevice = deviceArray[indexPath.row]
                                logVerbose( "[ %@ ][ %@ ]", currentStateName(), selectedDevice.netbiosName )

                                if let userNamePassword = UserDefaults.standard.string( forKey: selectedDevice.netbiosName ) {
                                    let     credentialsArray = userNamePassword.components( separatedBy: "/" )
                                    
                                    devicePassword = credentialsArray[1]
                                    deviceUserName = credentialsArray[0]
                                    
                                    showActivityIndicator( true )

                                    nasCentral.connectTo( selectedDevice, deviceUserName, devicePassword, self )
                                }
                                else {
                                    promptForLoginCredentialsFor( selectedDevice )
                                }
                                
        case .shareSelect:      currentState  = .navigating
                                selectedShare = shareArray[indexPath.row]
                                logVerbose( "[ %@ ][ %@ ]", currentStateName(), selectedShare )

                                showActivityIndicator( true )

                                nasCentral.openShare( selectedShare, self )

        case .navigating:       if mode == .dataStoreLocation {
                                    if targetDirectoryIndex == GlobalConstants.noSelection {
                                        pathsOnShare.append( tableDataArray[indexPath.row] )
                                        logVerbose( "[ %@ ][ %@ ]", currentStateName(), currentPath() )
                                        showActivityIndicator( true )

                                        nasCentral.fetchDirectoriesFrom( selectedShare, currentPath(), self )
                                    }

                                }
                                else {
                                    promptForActionToTakeOnRowAt( indexPath )
                                }

        }

    }


    
    // MARK: UITableViewDelegate Utility Methods
    
    private func promptForActionToTakeOnRowAt(_ indexPath: IndexPath ) {
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.WhatAction", comment: "What action would like to take?" ), message: "", preferredStyle : .alert)
        
        let     openAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Open", comment: "Open" ), style: .default )
        { ( alertAction ) in
            logVerbose( "Open Action ... [ %@ ]", self.tableDataArray[indexPath.row] )
            self.pathsOnShare.append( self.tableDataArray[indexPath.row] )
            self.showActivityIndicator( true )

            self.nasCentral.fetchDirectoriesFrom( self.selectedShare, self.currentPath(), self )
        }

        let     setAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.SetAsMediaRepository", comment: "Set as Media Repository" ), style: .default )
        { ( alertAction ) in
            self.pathsOnShare.append( self.tableDataArray[indexPath.row] )
            logVerbose( "Set as Media Repository Action ... [ %@ ]", self.currentPath() )
            
            self.navigatorCentral.dataSourceLocation = .nas
            self.nasCentral.saveDataSourceAccessKey( self.currentPath(), self )
            
            self.myTableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle )
            
            self.promptToScanNow()
        }

        let     cancelAction = UIAlertAction.init(title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addAction( openAction   )
        alert.addAction( setAction    )
        alert.addAction( cancelAction )

        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptForLoginCredentialsFor(_ device : SMBDevice ) {
        guard let nasLoginVC : NasLoginViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.nasLogin ) as? NasLoginViewController else {
            logTrace( "Error!  Unable to load NasLoginViewController!" )
            return
        }
        
        logTrace()
        nasLoginVC.delegate = self
        nasLoginVC.device   = device
        
        nasLoginVC.preferredContentSize   = CGSize( width: myTableView.frame.width, height: 280 )
        nasLoginVC.modalPresentationStyle = .formSheet
        
        nasLoginVC.popoverPresentationController?.delegate                 = self
        nasLoginVC.popoverPresentationController?.permittedArrowDirections = .up
        nasLoginVC.popoverPresentationController?.sourceRect               = CGRectMake( 50, 50, 50, 50 )
        nasLoginVC.popoverPresentationController?.sourceView               = view
        
        present( nasLoginVC, animated: true, completion: nil )
    }
    
    
    private func promptForPermissionToImport(_ filename : String ) {
        let     alert  = UIAlertController.init( title         : NSLocalizedString( "AlertTitle.AreYouSureImport",         comment: "Are you sure you want to import this file?" ),
                                                 message       : NSLocalizedString( "AlertMessage.ImportingIsDestructive", comment: "Importing an improperly formatted CSV file can fail or have an unpredicable outcome.  To prevent this, we will attempt to validate your CSV file before importing it.  Even so, if the import fails, you may lose any data you have created and you may have to delete the app and start over again." ),
                                                 preferredStyle: .alert)
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .destructive )
        { ( alertAction ) in
            logVerbose( "OK Action ... [ %@/%@ ]", self.currentPath(), filename )
            let     fullPath = self.currentPath() + "/" + filename
            
            self.showActivityIndicator( true )
            self.nasCentral.fetchFileOn( self.openShare, fullPath, self )
        }
        
        let     cancelAction = UIAlertAction.init(title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        alert.addAction( okAction     )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }

    
    private func promptToScanNow() {
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ScanNowPrompt", comment: "Would you like for us to scan your repository now?" ), message: "", preferredStyle : .alert)
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .default )
        { ( alertAction ) in
            logTrace( "Yes Action" )
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.navigationController?.popToRootViewController(animated: true )
            }
            else {
                if let settingsViewController = self.navigationController?.viewControllers[1] {
                    self.navigationController?.popToViewController( settingsViewController, animated: true)
                }
                
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
