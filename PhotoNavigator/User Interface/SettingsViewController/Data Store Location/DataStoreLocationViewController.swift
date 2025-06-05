//
//  DataLocationViewController.swift
//  WineStock
//
//  Created by Clint Shank on 1/21/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class DataLocationViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var myTableView         : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct CellIDs {
        static let basic  = "DataLocationViewControllerCell"
        static let detail = "DataLocationViewControllerDetailCell"
    }
    
    private struct CellIndexes {
        static let device = 0
        static let nas    = 2
        static let unused = 3
    }
    
    private struct StoryboardIds {
        static let nasSelector      = "NasDriveSelectorViewController"
        static let transferProgress = "TransferProgressViewController"
    }
    
    private var     canSeeNasFolders = false
    private let     nasCentral       = NASCentral.sharedInstance
    private var     navigatorCentral = NavigatorCentral.sharedInstance
    private var     selectedOption   = CellIndexes.device
    private var     userDefaults     = UserDefaults.standard
    
    private let optionArray = [ NSLocalizedString( "Title.Device",     comment: "Device" ),
                                NSLocalizedString( "Title.InNASDrive", comment: "Network Accessible Storage" ) ]
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title =  NSLocalizedString( "Title.SaveDataIn", comment: "Save Data In?" )
        
        let location = navigatorCentral.getStringFromUserDefaults( UserDefaultKeys.dataStoreLocation )
        
        if location.isEmpty {
            selectedOption = CellIndexes.device
        }
        else {
            switch location {
                case DataLocationName.device:      selectedOption = CellIndexes.device
                case DataLocationName.nas:         selectedOption = CellIndexes.nas
                case DataLocationName.shareNas:    selectedOption = CellIndexes.nas
                default:                           logTrace( "ERROR!  SBH!" )
            }

        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        canSeeNasFolders = false
        nasCentral.canSeeNasDataSourceFolders( self )
        
        myActivityIndicator.isHidden = false
        myActivityIndicator.startAnimating()
        
        loadBarButtonItems()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let     message = NSLocalizedString( "InfoText.DataStoreLocation", comment: "We provide support for three different storage locations...\n\n   (a) on your device (default),\n   (b) in the cloud and \n   (c) on a Network Accessible Storage (NAS) unit. \n\nThe key point here is that there is no sharing on the device, if you chose the cloud then your data can be shared across all of your devices and if you chose NAS then anyone who has access to your Wi-Fi can access it." )

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        configureBackBarButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) )
    }
    

}



// MARK: NASCentralDelegate Methods

extension DataLocationViewController : NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )
        
        self.canSeeNasFolders = canSeeNasFolders
        
        myActivityIndicator.stopAnimating()
        myActivityIndicator.isHidden = true
        myTableView.reloadData()
    }

    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension DataLocationViewController : UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension DataLocationViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     useDetailCell = ( indexPath.row == CellIndexes.nas ) && canSeeNasFolders && ( selectedOption == CellIndexes.nas )
        let     cellID        = useDetailCell ? CellIDs.detail : CellIDs.basic
        
        guard let cell = tableView.dequeueReusableCell( withIdentifier: cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }

        cell.textLabel?.text = optionArray[indexPath.row]
        cell.accessoryType   = ( indexPath.row == selectedOption ) ? .checkmark : .none
        
        if useDetailCell {
            let     descriptor = navigatorCentral.dataStoreDescriptor
            let     fullPath   = String( format: "%@/%@/%@", descriptor.netbiosName, descriptor.share, descriptor.path )
            
            cell.detailTextLabel?.text = fullPath
        }
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension DataLocationViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow( at: indexPath, animated: false )
        
        if  indexPath.row == selectedOption && indexPath.row != CellIndexes.nas {
            return
        }
        
        switch indexPath.row {
        case CellIndexes.device:
            tableView.reloadData()
            // NOTE - We are assuming that the data on the device is either more current or at least up to date
            //        with where ever it was previously stored (NAS) so we don't have to copy any files.
            presentConfirmationForMoveToDevice()

        case CellIndexes.nas:
            launchNasSelectorViewController()

        default:
            logTrace( "ERROR!  SBH!" )
        }
        
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods
    
    private func launchNasSelectorViewController() {
        guard let nasDriveSelector : NasDriveSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.nasSelector ) as? NasDriveSelectorViewController else {
            logTrace( "Error!  Unable to load NasDriveSelectorViewController!" )
            return
        }
        
        logTrace()
        navigationController?.pushViewController( nasDriveSelector, animated: true )
    }
    
    
    private func presentConfirmationForMoveToDevice() {
        var     message = NSLocalizedString( "AlertMessage.DataWillBeMovedTo", comment: "When you hit the OK button we will kill the app.  When you re-start the app your data will be moved to your " )
        let     title   = NSLocalizedString( "Title.DataStoreLocation", comment: "Data Store Location" )
        
        message += NSLocalizedString( "Title.Device", comment: "Device" )
        
        let     alert = UIAlertController.init( title : title, message : message, preferredStyle : .alert )

        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action" )
            self.navigatorCentral.dataStoreLocation = ( .device )
            UserDefaults.standard.removeObject(forKey: UserDefaultKeys.dataStoreDescriptor )

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                exit( 0 )
            })

        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addAction( cancelAction )
        alert.addAction( okAction     )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}
