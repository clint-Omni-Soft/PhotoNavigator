//
//  PleaseWaitViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 5/26/20.
//  Copyright © 2024 Omni-Soft, Inc. All rights reserved.
//

import UIKit



class PleaseWaitViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var pleaseWaitLabel   : UILabel!
    @IBOutlet weak var stayOfflineButton : UIButton!
    
    
    // MARK: Private Variables
    
    private var alertQueue          : [ (String, String) ] = []
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private var displayingAlert     = false
    private var displayRecovery     = false
    private let navigatorCentral    = NavigatorCentral.sharedInstance
    private let nasCentral          = NASCentral.sharedInstance
    private let notificationCenter  = NotificationCenter.default
    private var ready               = false

    
    // MARK: UIViewController Lifecycle Methods

    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        pleaseWaitLabel.text = NSLocalizedString( "LabelText.PleaseWaitWhileWeConnect", comment: "Please wait while we connect to your external device ..." )
        stayOfflineButton.setTitle( NSLocalizedString( "ButtonTitle.StayOffline", comment: "Stay Offline" ), for: .normal)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        activityIndicator.startAnimating()
        registerForNotifications()
        
        deviceAccessControl.reset()
        navigatorCentral.stayOffline = false
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        notificationCenter.removeObserver( self )
    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func cannotReadAllDbFiles( notification: NSNotification ) {
        logTrace()
        promptForRecoveryAction()
    }

    
    @objc func cannotSeeExternalDevice( notification: NSNotification ) {
        logTrace()
        displayAlert(title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ), message: NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
    }

    
    @objc func connectingToExternalDevice( notification: NSNotification ) {
        logTrace()
        pleaseWaitLabel  .isHidden = true
        stayOfflineButton.isHidden = true
        
        navigatorCentral.stayOffline = false

        displayAlert(title: NSLocalizedString( "AlertMessage.ConnectingToExternalDevice", comment: "Connecting to your external device." ), message: "" )
    }

    
    @objc func externalDeviceLocked( notification: NSNotification ) {
        logTrace()
        let     format  = NSLocalizedString( "AlertMessage.ExternalDriveLocked", comment: "The database on your external drive is locked by another user [ %@ ].  You can wait until the other user closes the app (which unlocks it) or make you changes offline and upload them when the drive is no longer locked." )
        let     message = String( format: format, deviceAccessControl.ownerName )

        displayAlert(title: NSLocalizedString( "AlertTitle.Warning", comment: "Warning!" ), message: message )
    }

    
    @objc func ready( notification: NSNotification ) {
        logVerbose( "%@", displayingAlert ? "Do nothing!  displayingAlert" : "" )
        ready = true

        if !displayingAlert && !deviceAccessControl.updating {
            switchToMainApp()
        }
        
    }
    
    
    @objc func transferringDatabase( notification: NSNotification ) {
        logTrace()
        stayOfflineButton.isHidden = true
        pleaseWaitLabel  .isHidden = true
        
        navigatorCentral.stayOffline = false
        
        displayAlert(title: NSLocalizedString( "AlertMessage.UpdatingExternalDevice", comment: "Please wait while we update the database with the most recent changes." ), message: "" )
    }


    @objc func unableToConnectToExternalDevice( notification: NSNotification ) {
        logTrace()
        displayAlert(title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ), message: NSLocalizedString( "AlertMessage.UnableToConnect", comment: "We are unable to connect to your external device.  Move closer to your WiFi network and try again." ) )
    }

    
    @objc func updatingExternalDevice( notification: NSNotification ) {
        logTrace()
        stayOfflineButton.isHidden = true
        pleaseWaitLabel  .isHidden = true
        
        navigatorCentral.stayOffline = false

        displayAlert(title: NSLocalizedString( "AlertMessage.UpdatingExternalDevice", comment: "Please wait while we update the database with the most recent changes." ), message: "" )
    }
    


    // MARK: Target/Action Methods
    
    @IBAction func stayOfflineButtonTouched(_ sender: UIButton) {
        logTrace()
        if  navigatorCentral.dataStoreLocation == .nas || navigatorCentral.dataStoreLocation == .shareNas {
            nasCentral.emptyQueue()
        }
        
        makeSureUserHasBeenWarned()
    }
    


    // MARK: Utility Methods
    
    private func disableControls() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        pleaseWaitLabel  .isHidden = true
    }
    
    
    private func displayAlert( title: String, message: String ) {
        if displayingAlert {
            logVerbose( "displayingAlert!  Queuing this one.\n    [ %@ ][ %@ ]", title, message )
            alertQueue.append( (title, message) )
            return
        }
        
        logVerbose( "\n    [ %@ ][ %@ ]", title, message )

        let     alert = UIAlertController.init( title: title, message: message, preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action" )
            self.displayingAlert = false

            if self.alertQueue.isEmpty {
                if self.ready {
                    self.switchToMainApp()
                }
                else if self.displayRecovery {
                    self.promptForRecoveryAction()
                }

            }
            else {
                let queuedAlert = self.alertQueue.first!
                
                self.alertQueue.removeFirst()
                self.displayAlert(title: queuedAlert.0, message: queuedAlert.1 )
            }
            
        }
        
        alert.addAction( okAction )
        
        displayingAlert = true

        present( alert, animated: true, completion: nil )
    }
    
    
    private func makeSureUserHasBeenWarned() {
        logTrace()
        disableControls()

        if !flagIsPresentInUserDefaults( UserDefaultKeys.dontRemindMeAgain ) {
            warnUser()
        }
        else {
            deviceAccessControl.byMe        = true
            navigatorCentral.stayOffline = true
            
            if !displayingAlert && !deviceAccessControl.updating {
                switchToMainApp()
            }
            
        }
        
    }
    

    private func promptForRecoveryAction() {
        logTrace()
        if displayingAlert {
            displayRecovery = true
            return
        }
        
        displayingAlert = true
        stayOfflineButton.isHidden = true
        disableControls()
        
        let formatString  = NSLocalizedString( "AlertMessage.CannotReadAllDbFiles", comment: "The last update to the database on the remote device did not complete properly.  Please contact the user of '%@' and ask them to re-submit their last post.  The database will remain locked until this is resolved." )
        let messageString = String(format: formatString, navigatorCentral.externalDeviceLastUpdatedBy )

        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.LastUpdateDidNotComplete", comment: "The Last Update Did NOT Complete" ), message: messageString, preferredStyle: .alert)

        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action" )
            self.displayingAlert = false
       }
              
        let     resubmitAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Resubmit", comment: "Resubmit" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Resubmit Action" )
            self.displayingAlert = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                self.navigatorCentral.didOpenDatabase = false
     
                self.nasCentral.copyDatabaseFromDeviceToNas( self.navigatorCentral )
            }
            
        }
        
        alert.addAction( okAction       )
        alert.addAction( resubmitAction )

        displayingAlert = true
        
        present( alert, animated: true, completion: nil )
    }


    private func registerForNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( cannotReadAllDbFiles(            notification: ) ), name: NSNotification.Name( rawValue: Notifications.cannotReadAllDbFiles       ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( cannotSeeExternalDevice(         notification: ) ), name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice    ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( connectingToExternalDevice(      notification: ) ), name: NSNotification.Name( rawValue: Notifications.connectingToExternalDevice ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( externalDeviceLocked(            notification: ) ), name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked       ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( ready(                           notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready                      ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( transferringDatabase(            notification: ) ), name: NSNotification.Name( rawValue: Notifications.transferringDatabase       ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( unableToConnectToExternalDevice( notification: ) ), name: NSNotification.Name( rawValue: Notifications.unableToConnect            ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( updatingExternalDevice(          notification: ) ), name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice     ), object: nil )
    }

    
    private func switchToMainApp() {
        logTrace()
        let     appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.switchToMainApp()
    }
    
    
    private func warnUser() {
        logTrace()
        disableControls()
        self.deviceAccessControl.byMe        = true
        self.navigatorCentral.stayOffline = true

        let     alert = UIAlertController.init( title:   NSLocalizedString( "AlertTitle.Warning",          comment: "Warning!" ),
                                                message: NSLocalizedString( "AlertMessage.OfflineWarning", comment: "We cannot connect to your remote storage.  Because this app is designed to work offline, you can make changes that we will upload the next time you connect to your remote storage.  Just be aware that if more than one person makes changes offline, your changes may be overwritten." ),
                                                preferredStyle: .alert)

        let     gotItAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.GotIt", comment: "Got it!" ), style: .default )
        { ( alertAction ) in
            logTrace( "Got It Action" )
            self.displayingAlert = false

            if !self.deviceAccessControl.updating {
                self.switchToMainApp()
            }
            
        }
        
        let     dontRemindMeAgainAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.DontRemindMeAgain", comment: "Don't remind me again." ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Don't Remind Me Again Action" )
            self.saveFlagInUserDefaults( UserDefaultKeys.dontRemindMeAgain )
            self.displayingAlert = false

            if !self.deviceAccessControl.updating {
                self.switchToMainApp()
            }
            
        }
        
        alert.addAction( gotItAction )
        
        if !flagIsPresentInUserDefaults( UserDefaultKeys.dontRemindMeAgain ) {
            alert.addAction( dontRemindMeAgainAction )
        }

        displayingAlert = true
        
        present( alert, animated: true, completion: nil )
    }

    
}


