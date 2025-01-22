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
    private var lastSelection       = GlobalIndexPaths.noSelection
    private var navigatorCentral    = NavigatorCentral.sharedInstance
    private var queuedSelection     = GlobalIndexPaths.noSelection
    private var sectionIndexTitles  : [String] = []
    private var sectionTitleIndexes : [Int]    = []
    private var showAllSections     = true
    private var searchEnabled       = false
    private var searchResults       : [MediaFile] = []
    private let userDefaults        = UserDefaults.standard

    
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
        
        self.navigationItem.title = NSLocalizedString( "Title.Photos", comment: "Photos" )
        
        myTextField.delegate      = self
        myTextField.isHidden      = !searchEnabled
        myTextField.returnKeyType = .done
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logVerbose( "resigningActive[ %@ ]", stringFor( navigatorCentral.resigningActive ) )
        super.viewWillAppear( animated )
        
        if !navigatorCentral.didOpenDatabase {
            navigatorCentral.openDatabaseWith( self )
        }
        else {
            if !navigatorCentral.resigningActive {
                configureSortButtonTitle()
                loadBarButtonItems()
                registerForNotifications()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                    if self.queuedSelection != GlobalIndexPaths.noSelection {
                        self.updateAccessoryOnRowAt( self.queuedSelection )
                        self.queuedSelection = GlobalIndexPaths.noSelection
                    }

                    self.buildSectionTitleIndex()
                    self.myTableView.reloadData()

                    if self.lastSelection != GlobalIndexPaths.noSelection {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                            self.scrollToLastSelectedItem()
                        }
                        
                    }

                }
                
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
        myTableView.reloadData()
    }



    // MARK: Target / Action Methods
    
    @IBAction func hidePrimaryBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( true )
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

        if self.navigatorCentral.numberOfMediaFilesLoaded != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.scrollToLastSelectedItem()
            }
            
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
       
        logTrace()
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
        if navigatorCentral.dataSourceLocation == .nas {
            let title = NSLocalizedString( "LabelText.SortedOn", comment: "Sorted on: " ) + navigatorCentral.nameForCurrentSortOption()
            
            sortButton.setTitle( title, for: .normal )
            sortButton.isHidden = false
        }
        else {
            sortButton.isHidden = true
        }

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
        let arrowImage          = UIImage(named: showAllSections      ? "arrowUp"         : "arrowDown" )
        let searchImage         = UIImage(named: myTextField.isHidden ? "magnifyingGlass" : "magnifyingGlassXout" )
        var leftBarButtonItems  = [UIBarButtonItem]()
        var rightBarButtonItems = [UIBarButtonItem]()
        let weHaveData          = ( navigatorCentral.dataSourceLocation == .nas ) ? ( navigatorCentral.numberOfMediaFilesLoaded > 0 ) : ( navigatorCentral.numberOfDeviceAssetsLoaded > 0 )

        if UIDevice.current.userInterfaceIdiom == .pad {
            leftBarButtonItems.append( UIBarButtonItem.init( barButtonSystemItem: .close, target: self, action: #selector( hidePrimaryBarButtonTouched(_: ) ) ) )
        }

        if weHaveData {
            leftBarButtonItems.append( UIBarButtonItem.init( image: arrowImage,  style: .plain, target: self, action: #selector( showAllBarButtonTouched(_ :) ) ) )
        }
        
        navigationItem.leftBarButtonItems = leftBarButtonItems

        if UIDevice.current.userInterfaceIdiom == .pad {
            rightBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "settings" ), style: .plain, target: self, action: #selector( settingsBarButtonTouched(_:) ) ) )
        }
        
        if weHaveData && navigatorCentral.dataSourceLocation == .nas {
            rightBarButtonItems.append( UIBarButtonItem.init( image: searchImage, style: .plain, target: self, action: #selector( searchToggleBarButtonTouched(_:) ) ) )
        }
        
        navigationItem.rightBarButtonItems = rightBarButtonItems
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
        NotificationCenter.default.addObserver( self, selector: #selector( self.ready(                    notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready             ), object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( self.mediaDataReloaded(        notification: ) ), name: NSNotification.Name( rawValue: Notifications.mediaDataReloaded ), object: nil )
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
        logVerbose( "section[ %d ]  isOpen[ %@ ]", section, stringFor( isOpen ) )
        selectedSection = ( selectedSection == section ) ? GlobalConstants.noSelection : section
        showAllSections = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.buildSectionTitleIndex()
            self.configureSortButtonTitle()
            self.loadBarButtonItems()
            
            self.myTableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                let indexPath = IndexPath( row: NSNotFound, section: section )
                
                self.myTableView.scrollToRow(at: indexPath, at: .top, animated: false )
            }

        }

    }
    
    
}



// MARK: MediaViewerViewControllerDelegate Methods

extension MediaListViewController: MediaViewerViewControllerDelegate {

    func mediaViewerViewController(_ mediaViewerVC: MediaViewerViewController, didShowMediaAt indexPath: IndexPath) {
        logVerbose( "[ %@ ]  resigningActive[ %@ ]", stringFor( indexPath ), stringFor( navigatorCentral.resigningActive ) )
        if !navigatorCentral.resigningActive {
            DispatchQueue.main.async {
                self.updateAccessoryOnRowAt( indexPath )
                self.myTableView.reloadData()
                self.scrollToLastSelectedItem()
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
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.scrollToLastSelectedItem()
        }

    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadMediaData: Bool ) {
        logVerbose( "loaded [ %d ] MediaFiles", navigatorCentral.numberOfMediaFilesLoaded )
        
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.scrollToLastSelectedItem()
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
        
        if appDelegate.mediaViewer != nil {
            displayMediaAt( indexPath )
        }
        else {
            if UIDevice.current.userInterfaceIdiom == .phone {
                let myTabBarViewController = appDelegate.window?.rootViewController as! TabBarViewController
                
                myTabBarViewController.selectedIndex = 1
                logTrace( "switching to viewer" )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                    self.displayMediaAt( indexPath )
                }
                
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
        if navigatorCentral.dataSourceLocation == .nas {
            appDelegate.mediaViewer.displayMediaFileAt( indexPath, self )
        }
        else {  // Device
            appDelegate.mediaViewer.displayAssetAt( indexPath, self )
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
