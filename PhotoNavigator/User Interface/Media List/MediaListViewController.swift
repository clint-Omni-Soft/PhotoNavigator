//
//  MediaListViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/5/24.
//

import UIKit
import Photos



class MediaListViewController: UIViewController {

    
    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var myTextField: UITextField!
    @IBOutlet weak var sortButton : UIButton!
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let cellID              = "MediaListViewControllerCell"
        static let cellIDAsset         = "MediaListViewControllerAssetCell"
        static let lastSectionKey      = "ListLastSection"
        static let locationRowHeight   = CGFloat( 66.0 )
        static let rowHeight           = CGFloat( 44.0 )
        static let sectionHeaderHeight = CGFloat( 44.0 )
        static let sectionHeaderID     = "MediaListViewControllerSectionCell"
    }
    
    private struct StoryboardIds {
        static let settings    = "SettingsViewController"
        static let sortOptions = "SortOptionsViewController"
    }
    
    private let appDelegate         = UIApplication.shared.delegate as! AppDelegate
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private var navigatorCentral    = NavigatorCentral.sharedInstance
    private var notificationCenter  = NotificationCenter.default
    private var queuedSelection     = GlobalIndexPaths.noSelection
    private var sectionIndexTitles  : [String] = []
    private var sectionTitleIndexes : [Int]    = []
    private var searchEnabled       = false
    private var searchResults       : [MediaFile] = []
    private var showAllSections     = true
    private let userDefaults        = UserDefaults.standard

    private var lastSelection: IndexPath {
        get {
            let lastValue = getStringFromUserDefaults( UserDefaultKeys.lastSelectionIndexPath )
            let indexPath = indexPathFrom( lastValue )
            
            return indexPath
        }
        
        set ( indexPath ) {
            let newIndexPathString = stringFor( indexPath )
            
            saveStringToUserDefaults( newIndexPathString, for: UserDefaultKeys.lastSelectionIndexPath )
        }
        
    }
    
    
    // This is used only when we are sorting on Type
    private var selectedSection: Int {
        get {
            var     section = GlobalConstants.noSelection
            
            if let lastSection = userDefaults.string(forKey: Constants.lastSectionKey ) {
                let thisSection = Int( lastSection ) ?? GlobalConstants.noSelection
                
                section = ( thisSection < myTableView.numberOfSections ) ? thisSection : GlobalConstants.noSelection
            }
            
            return section
        }
        
        set ( section ) {
            userDefaults.set( String( format: "%d", section ), forKey: Constants.lastSectionKey )
        }
        
    }

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.Media", comment: "Media" )
        
        myTextField.delegate      = self
        myTextField.isHidden      = !searchEnabled
        myTextField.returnKeyType = .done
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        var scrollToTop = false
        
        if !navigatorCentral.didOpenDatabase {
            navigatorCentral.openDatabaseWith( self )
        }
        else {
            if navigatorCentral.didRescanRepo {
                logTrace( "Resetting after rescan" )
                navigatorCentral.didRescanRepo = false
                
                lastSelection   = GlobalIndexPaths.noSelection
                queuedSelection = GlobalIndexPaths.noSelection
                scrollToTop     = true
            }

            configureSortButtonTitle()
            registerForNotifications()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                if self.queuedSelection != GlobalIndexPaths.noSelection {
                    self.selectedSection = self.queuedSelection.section
                    self.buildSectionTitleIndex()
                    self.myTableView.reloadData()
                    
                    self.updateAccessoryOnRowAt( self.queuedSelection )
                    self.queuedSelection = GlobalIndexPaths.noSelection
                }
                else {
                    self.buildSectionTitleIndex()
                    self.myTableView.reloadData()
                }

                if scrollToTop {
                    self.myTableView.setContentOffset( .zero, animated: true )
                }
                
                if self.lastSelection != GlobalIndexPaths.noSelection {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                        self.scrollToLastSelectedItem()
                        self.displayMediaAt( self.lastSelection )
                    }
                    
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                    self.loadBarButtonItems()
                }
                
            }
            
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        logTrace()
        super.viewDidAppear(animated)
        
        var howToUseShown = false
        
        if let _ = userDefaults.string(forKey: UserDefaultKeys.howToUseShown ) {
            howToUseShown = true
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            if !howToUseShown {
                launchSettingsViewController()
            }

        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            let tableIsEmpty = self.myTableView.numberOfSections == 0

            if tableIsEmpty && howToUseShown {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.MediaListRepoNotSet",   comment: "Media Repo NOT Set!" ),
                                   message: NSLocalizedString( "AlertMessage.MediaListRepoNotSet", comment: "Tap on the Settings icon (cog wheel) then select Media Repository and designate the location of your repository.  Once you have done that, go back to Settings then select Scan Media Repository." ) )
            }

        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    
    
    // MARK: NSNotification Methods
    
    @objc func ready( notification: NSNotification ) {
        logTrace()
        myTableView.reloadData()
    }


    @objc func mediaDataReloaded( notification: NSNotification ) {
        logTrace()
        navigatorCentral.didRescanRepo = false
        
        lastSelection   = GlobalIndexPaths.noSelection
        queuedSelection = GlobalIndexPaths.noSelection
        
        myTableView.reloadData()
    }



    // MARK: Target / Action Methods
    
    @IBAction func displayModeBarButtonTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        presentDisplayOptions( sender )
    }
    
    
    @IBAction func hidePrimaryBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( true )
    }

    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let message = NSLocalizedString( "InfoText.MediaList1", comment: "Touching any media title in the list will load the it into the Media Viewer.\n\nNavigation Bar Buttons:\n\n" )
                    + NSLocalizedString( "InfoText.MediaList2", comment: "When your media can be grouped, an up/down caret will be displayed which you can use to open/close all sections of the table.  Touching on a section header will open/close that section." )
                    + NSLocalizedString( "InfoText.MediaList3", comment: "When reading from a NAS drive, you have two more controls\n" )
                    + NSLocalizedString( "InfoText.MediaList4", comment: "(1) A 'Sorted on:' button which you can use to have the the list sorted by Filename or Relative Path.\n" )
                    + NSLocalizedString( "InfoText.MediaList5", comment: "(2) A 'Magnifying glass' icon - Touch to search on the name of a media file.\n\n" )
                    + NSLocalizedString( "InfoText.MediaList6", comment: "If you are on an iPad, you have two more controls.\n" )
                    + NSLocalizedString( "InfoText.MediaList7", comment: "(1) A 'Shaded Circle with a X in the middle' icon - Touch to hide the media list and make the Media View full screen.\n" )
                    + NSLocalizedString( "InfoText.MediaList8", comment: "(2) A 'Gears' icon - Touch to go to the Setting view." )

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }
    
    
    @IBAction func searchToggleBarButtonTouched(_ sender : UIBarButtonItem ) {
        searchEnabled = !searchEnabled
        
        logVerbose( "searchEnabled[ %@ ]", stringFor( searchEnabled ) )
        myTextField.isHidden = !searchEnabled
        sortButton .isHidden =  searchEnabled
        
        if searchEnabled {
            myTextField.text = ""
            myTextField.becomeFirstResponder()
        }
        else {
            myTextField.resignFirstResponder()
        }
        
        loadBarButtonItems()
        myTableView.reloadData()
    }
    
    
    @IBAction func settingsBarButtonTouched(_ sender : UIBarButtonItem ) {
        launchSettingsViewController()
    }
    
        
    @IBAction func showAllBarButtonTouched(_ sender : UIBarButtonItem ) {
        logVerbose( "[ %@ ]", stringFor( showAllSections ) )
        selectedSection = GlobalConstants.noSelection
        showAllSections = !showAllSections
        
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.scrollToLastSelectedItem()
        }
            
    }
    
    
    @IBAction func sortButtonTouched(_ sender: Any) {
        logTrace()
        presentSortOptions()
    }
    
    

    // MARK: Utility Methods
    
    private func buildSectionTitleIndex() {
        if navigatorCentral.dataSourceLocation != .nas {
            // navigatorCentral builds this for us when it loads the PHAssets
            return
        }
       
//        logTrace()
        sectionIndexTitles .removeAll()
        sectionTitleIndexes.removeAll()
        
        let sortDescriptor = navigatorCentral.sortDescriptor
        let sortType       = sortDescriptor.0
        
        if sortType == SortOptions.byFilename {
            for mediaArray in navigatorCentral.mediaFileArrayOfArrays {
                let mediaFile      = mediaArray.first!
                let nameStartsWith = ( mediaFile.filename?.prefix(1).uppercased() )!
                    
                sectionTitleIndexes.append( mediaArray.count )
                sectionIndexTitles .append( nameStartsWith   )
            }
            
        }
        
    }
    
    
    private func configureSortButtonTitle() {
//        logTrace()
        let isEnabled = navigatorCentral.dataSourceLocation == .nas
        let title     = isEnabled ? NSLocalizedString( "LabelText.SortedOn", comment: "Sorted on: " ) + navigatorCentral.nameForCurrentSortOption() : NSLocalizedString( "LabelText.ThisDevice", comment: "This Device" )


        sortButton.setTitle( title, for: .normal )
        sortButton.isEnabled = isEnabled
    }
    
    
    private func lastAccessedMediaFile() -> IndexPath {
        guard let lastMediaFileGuid = userDefaults.object(forKey: UserDefaultKeys.lastAccessedMediaFileGuid ) as? String else {
            return GlobalIndexPaths.noSelection
        }
        
        for section in 0...navigatorCentral.mediaFileArrayOfArrays.count - 1 {
            let sectionArray = navigatorCentral.mediaFileArrayOfArrays[section]
            
            if !sectionArray.isEmpty {
                for row in 0...sectionArray.count - 1 {
                    let pin = sectionArray[row]
                    
                    if pin.guid == lastMediaFileGuid {
                        return IndexPath(row: row, section: section )
                    }
                    
                }
                
            }
            
        }
        
        return GlobalIndexPaths.noSelection
    }
    
    
    private func launchSettingsViewController() {
        guard let settingsVC: SettingsViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.settings ) as? SettingsViewController else {
            logTrace( "Error!  Unable to load SettingsViewController!" )
            return
        }

        logTrace()
        navigationController?.pushViewController( settingsVC, animated: true )
    }

    
    private func loadBarButtonItems() {
        logTrace()
        let caretImage          = UIImage(named: showAllSections ? "arrowUp" : "arrowDown" )
        var leftBarButtonItems  = [UIBarButtonItem]()
        var rightBarButtonItems = [UIBarButtonItem]()
        let searchImage         = UIImage(named: myTextField.isHidden ? "magnifyingGlass" : "magnifyingGlassXout" )
        let weHaveData          = ( navigatorCentral.dataSourceLocation == .nas ) ? ( navigatorCentral.numberOfMediaFilesLoaded > 0 ) : ( navigatorCentral.numberOfDeviceAssetsLoaded > 0 )

        if UIDevice.current.userInterfaceIdiom == .pad {
            leftBarButtonItems.append( UIBarButtonItem.init( barButtonSystemItem: .close, target: self, action: #selector( hidePrimaryBarButtonTouched(_: ) ) ) )
        }

        leftBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) ) )

        if myTableView.numberOfSections > 1 {
            leftBarButtonItems.append( UIBarButtonItem.init( image: caretImage,  style: .plain, target: self, action: #selector( showAllBarButtonTouched(_ :) ) ) )
        }
        
        navigationItem.leftBarButtonItems = leftBarButtonItems

        if UIDevice.current.userInterfaceIdiom == .pad {
            rightBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "gear" ), style: .plain, target: self, action: #selector( settingsBarButtonTouched(_:) ) ) )
        }
        
        if weHaveData && navigatorCentral.dataSourceLocation == .nas {
            rightBarButtonItems.append( UIBarButtonItem.init( image: searchImage, style: .plain, target: self, action: #selector( searchToggleBarButtonTouched(_:) ) ) )
        }
        
        if lastSelection != GlobalIndexPaths.noSelection {
            let image = navigatorCentral.stayInFolder ? ( navigatorCentral.shuffleImages ? UIImage(named: "shuffle" ) : UIImage(named: "repeat" ) ) : UIImage(named: "pin" )
            
            rightBarButtonItems.append( UIBarButtonItem.init( image: image, style: .plain, target: self, action: #selector( displayModeBarButtonTouched(_:) ) ) )
        }
        
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    
    private func presentDisplayOptions(_ displayOptionsBarButtonItem : UIBarButtonItem ) {
        let alert       = UIAlertController( title: NSLocalizedString( "AlertTitle.DisplayOptions", comment: "Display Options" ), message: nil, preferredStyle: .actionSheet )
        let mediaViewer = appDelegate.mediaViewer
        
        if mediaViewer == nil {
            logTrace( "MediaViewer is nil!" )
        }

        let     streamAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Stream", comment: "Stream in Order" ), style: .default ) {
            ( alertAction ) in
            logTrace( "Stream Action" )
            
            self.navigatorCentral.shuffleImages = false
            self.navigatorCentral.stayInFolder  = false
            
            self.loadBarButtonItems()
        }
        
        let     repeatAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Loop", comment: "Loop in Folder" ), style: .default ) {
            ( alertAction ) in
            logTrace( "Loop Action" )
            
            self.navigatorCentral.shuffleImages = false
            self.navigatorCentral.stayInFolder  = true

            self.loadBarButtonItems()
        }
        
        let     shuffleAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Shuffle", comment: "Shuffle in Folder" ), style: .default ) {
            ( alertAction ) in
            logTrace( "Shuffle Action" )
            
            self.navigatorCentral.shuffleImages = true
            self.navigatorCentral.stayInFolder  = true
            
            self.loadBarButtonItems()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel ) {
            ( alertAction ) in
            logTrace( "Cancel Action" )
        }
        
        alert.addAction( streamAction  )
        alert.addAction( repeatAction  )
        alert.addAction( shuffleAction )
        alert.addAction( cancelAction  )
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.barButtonItem            = displayOptionsBarButtonItem
            alert.popoverPresentationController!.delegate                 = self
            alert.popoverPresentationController?.permittedArrowDirections = .any
            alert.popoverPresentationController?.permittedArrowDirections = .any
        }
            
        present( alert, animated: true )
    }
    
        
    private func presentSortOptions() {
        guard let sortOptionsVC: SortOptionsViewController = iPhoneViewControllerWithStoryboardId(storyboardId: StoryboardIds.sortOptions ) as? SortOptionsViewController else {
            logTrace( "ERROR: Could NOT load SortOptionsViewController!" )
            return
        }
        
        sortOptionsVC.delegate = self
        
        sortOptionsVC.modalPresentationStyle = .popover
        sortOptionsVC.preferredContentSize   = CGSize(width: myTableView.frame.width, height: 300 )

        sortOptionsVC.popoverPresentationController!.delegate                 = self
        sortOptionsVC.popoverPresentationController?.permittedArrowDirections = .any
        sortOptionsVC.popoverPresentationController?.sourceRect               = sortButton.frame
        sortOptionsVC.popoverPresentationController?.sourceView               = sortButton
        
        present( sortOptionsVC, animated: true, completion: nil )
    }
    
    
    private func registerForNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( self.ready(             notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready             ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( self.mediaDataReloaded( notification: ) ), name: NSNotification.Name( rawValue: Notifications.mediaDataReloaded ), object: nil )
    }
    
    
    private func scrollToLastSelectedItem() {
        if lastSelection != GlobalIndexPaths.noSelection {
            if myTableView.numberOfRows(inSection: lastSelection.section ) == 0 {
                logVerbose( "Do nothing! The selected row is in a section[ %d ] that is closed!", lastSelection.section )
                return
            }
            
            if showAllSections || lastSelection.section == selectedSection {
                myTableView.scrollToRow(at: lastSelection, at: .top, animated: true )
                logVerbose( "[ %@ ]  showAllSections[ %@ ]  selectedSection[ %d ]", stringFor( lastSelection ), stringFor( showAllSections ), selectedSection )
            }
            else {
                logTrace( "Do nothing ... lastSelection NOT exposed" )
            }
            
        }
        else {
            logTrace( "Do nothing ... lastSelection NOT set" )
        }
        
    }
    
    
    private func updateAccessoryOnRowAt(_ indexPath: IndexPath ) {
//        logVerbose( "old[ %@ ]  new[ %@ ]", stringFor( lastSelection ), stringFor( indexPath ) )
        if lastSelection != GlobalIndexPaths.noSelection {
            let previousRowSelected = myTableView.cellForRow(at: lastSelection )
            
            previousRowSelected?.accessoryType = .none
        }
        
        let currentRowSelected = myTableView.cellForRow(at: indexPath )
        
        currentRowSelected?.accessoryType = .checkmark
        lastSelection = indexPath
    }
    
    
}



// MARK: MediaFileViewControllerSectionCellDelegate Methods

extension MediaListViewController: MediaListViewControllerSectionCellDelegate {
    
    func mediaListViewControllerSectionCell(_ mediaListViewControllerSectionCell: MediaListViewControllerSectionCell, section: Int, isOpen: Bool) {
//        logVerbose( "section[ %d ]  isOpen[ %@ ]", section, stringFor( isOpen ) )
        selectedSection = ( selectedSection == section ) ? GlobalConstants.noSelection : section
        showAllSections = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.buildSectionTitleIndex()
            self.configureSortButtonTitle()
            
            self.myTableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                let indexPath = IndexPath( row: NSNotFound, section: section )
                
                self.myTableView.scrollToRow(at: indexPath, at: .top, animated: false )
                self.loadBarButtonItems()
            }

        }

    }
    
    
}



// MARK: MediaViewerViewControllerDelegate Methods

extension MediaListViewController: MediaViewerViewControllerDelegate {

    func mediaViewerViewController(_ mediaViewerVC: MediaViewerViewController, didShowMediaAt indexPath: IndexPath) {
        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        if self.viewIfLoaded?.window != nil {   // We have to be visible to do this
            DispatchQueue.main.async {
                self.updateAccessoryOnRowAt( indexPath )
                
                self.myTableView.reloadData()
                
                self.scrollToLastSelectedItem()
                self.loadBarButtonItems()
            }

        }
        else {
            queuedSelection = indexPath
        }

    }
    
    
}



// MARK: NavigatorCentralDelegate Methods

extension MediaListViewController: NavigatorCentralDelegate {
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )

        buildSectionTitleIndex()
        configureSortButtonTitle()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.scrollToLastSelectedItem()
            self.loadBarButtonItems()
            self.displayMediaAt( self.lastSelection )
        }

    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadMediaData: Bool ) {
        logVerbose( "loaded [ %d ] MediaFiles", navigatorCentral.numberOfMediaFilesLoaded )
        
        buildSectionTitleIndex()
        configureSortButtonTitle()

        lastSelection   = GlobalIndexPaths.noSelection
        queuedSelection = GlobalIndexPaths.noSelection
        
        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.myTableView.setContentOffset( .zero, animated: true )
            self.loadBarButtonItems()
        }

    }


}



// MARK: SortOptionsViewControllerDelegate Methods

extension MediaListViewController: SortOptionsViewControllerDelegate {
    
    func sortOptionsViewController(_ sortOptionsViewController: SortOptionsViewController, didSelectNewSortOption: Bool ) {
        logVerbose( "[ %@ ]", navigatorCentral.nameForCurrentSortOption() )
        configureSortButtonTitle()
        navigatorCentral.fetchMediaFilesWith( self )
    }
    
    
}



// MARK: - UIPopoverPresentationControllerDelegate method

extension MediaListViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: - UITableViewDataSource Methods

extension MediaListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 0
        
        if navigatorCentral.dataSourceLocation == .nas  {
            numberOfSections = searchEnabled ? 1 : ( navigatorCentral.numberOfMediaFilesLoaded == 0 ) ? 0 : navigatorCentral.mediaFileArrayOfArrays.count
        }
        else { // Device
            numberOfSections = navigatorCentral.deviceAssetArrayOfArrays.count
        }

        return numberOfSections
    }
    
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
       return sectionIndexTitles
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = navigatorCentral.dataSourceLocation == .nas ? Constants.cellID : Constants.cellIDAsset
            
        guard let cell = tableView.dequeueReusableCell( withIdentifier: cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let accessory : UITableViewCell.AccessoryType = ( lastSelection == indexPath ) ? .checkmark : .none

        if navigatorCentral.dataSourceLocation == .nas {
            let     mediaListCell = cell as! MediaListViewControllerCell
            let     mediaFile     = searchEnabled ? searchResults[indexPath.row] : navigatorCentral.mediaFileAt( indexPath )
            
            mediaListCell.initializeWith( mediaFile, accessory )
        }
        else {  // Device
            let assetCell = cell as! MediaListViewControllerAssetCell
            
            assetCell.initializeWith( navigatorCentral.deviceAssetAt( indexPath ), accessory )
        }

        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0
        
        if searchEnabled {
            numberOfRows = searchResults.count
        }
        else if navigatorCentral.dataSourceLocation == .nas {
            if showAllSections || ( selectedSection == section ) {
                numberOfRows = navigatorCentral.mediaFileArrayOfArrays[section].count
            }
            
        }
        else {  // Device
            if showAllSections || ( selectedSection == section ) {
                numberOfRows = navigatorCentral.deviceAssetArrayOfArrays[section].count
            }
            
        }
        
        return  numberOfRows
    }
    
    
}



    // MARK: UITableViewDelegate Methods

extension MediaListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false )

        if indexPath == lastSelection {
            return
        }
        
        logVerbose( "last[ %@ ]  new[ %@ ]", stringFor( lastSelection ), stringFor( indexPath ) )
        updateAccessoryOnRowAt( indexPath )
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            var myTabBarViewController: TabBarViewController!
            
            if appDelegate.window?.rootViewController != nil {
                if let tabBarController = appDelegate.window?.rootViewController as? TabBarViewController {
                    myTabBarViewController = tabBarController
                }
                
            }
            else {
                if let tabBarController = appDelegate.activeWindow?.rootViewController as? TabBarViewController {
                    myTabBarViewController = tabBarController
                }

            }
            
            myTabBarViewController.selectedIndex = 1
            logTrace( "switching to viewer" )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.displayMediaAt( indexPath )
            }
            
        }
        else {
            if appDelegate.mediaViewer != nil {
                displayMediaAt( indexPath )
            }
            else {
                logTrace( "ERROR!!!  iPad unable to register mediaViewer" )
            }
            
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
       if searchEnabled {
            return CGFloat.leastNormalMagnitude
        }
        
        var isHidden = true

        if navigatorCentral.dataSourceLocation == .nas {
            if navigatorCentral.mediaFileArrayOfArrays.count > 1 {
                isHidden = navigatorCentral.mediaFileArrayOfArrays[section].count == 0
            }
            
        }
        else if navigatorCentral.deviceAssetArrayOfArrays.count > 1 {
            isHidden = navigatorCentral.deviceAssetArrayOfArrays[section].count == 0
       }

        return isHidden ? CGFloat.leastNormalMagnitude : Constants.sectionHeaderHeight
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight = Constants.rowHeight
        
        if navigatorCentral.dataSourceLocation != .nas && navigatorCentral.deviceAssetAt( indexPath ).hasLocation() {
            rowHeight = Constants.locationRowHeight
        }
        
        return rowHeight
    }
    
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let     row = sectionTitleIndexes[index]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: index ), at: .middle , animated: true )
        }
        
        return row
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return searchEnabled ? "" : navigatorCentral.sectionTitleArray[ section ]
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if searchEnabled {
            return UITableViewCell.init()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.sectionHeaderID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let isOpen     = selectedSection == section
        let headerCell = cell as! MediaListViewControllerSectionCell
        
        headerCell.initializeFor( section, with: navigatorCentral.sectionTitleArray[ section ], isOpen: isOpen, self )

        return headerCell
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods

    private func displayMediaAt(_ indexPath: IndexPath ) {
        logTrace()
        if let mediaViewer = appDelegate.mediaViewer {
            if navigatorCentral.dataSourceLocation == .nas {
                mediaViewer.displayMediaFileAt( indexPath, self )
            }
            else {  // Device
                mediaViewer.displayAssetAt( indexPath, self )
            }

        }

    }
    
    
}



// MARK: UITextFieldDelegate Methods

extension MediaListViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField ) {
        guard let searchText = textField.text else {
            return
        }
        
        if searchText.isEmpty {
            searchResults = []
            myTableView.reloadData()
        }
        else if searchText.count > 1 {
            scanFor( searchText )
        }
        
    }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if ( string == "\n" ) {
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    
    
    // MARK: UITextFieldDelegate Utility Methods
    
    private func scanFor(_ searchString: String ) {
//        logVerbose( "[ %@ ]", searchString )
        searchResults = navigatorCentral.mediaFilesWith( searchString.components(separatedBy: " " ) )

        let sortedMediaFileArray = searchResults.sorted( by:
                    { (MediaFile1, MediaFile2) -> Bool in
                        MediaFile1.filename! < MediaFile2.filename!
                    } )

        searchResults = []
        
        // Discard duplicates
        for sortedMediaFile in sortedMediaFileArray {
            var saveIt = true
            
            for searchMediaFile in searchResults {
                if searchMediaFile.guid == sortedMediaFile.guid {
                    saveIt = false
                    break
                }
                
            }
            
            if saveIt {
                searchResults.append( sortedMediaFile )
            }
                
        }
            
        myTableView.reloadData()
    }
    
    

}
