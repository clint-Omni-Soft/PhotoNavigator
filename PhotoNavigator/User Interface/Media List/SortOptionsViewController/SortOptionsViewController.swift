//
//  SortOptionsViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/28/24.
//


import UIKit


protocol SortOptionsViewControllerDelegate: AnyObject {
    func sortOptionsViewController(_ sortOptionsViewController: SortOptionsViewController, didSelectNewSortOption: Bool )
}


class SortOptionsViewController: UIViewController {

    
    // MARK: Public Variables
    
    weak var delegate: SortOptionsViewControllerDelegate?
    
    @IBOutlet weak var cancelButton         : UIButton!
    @IBOutlet weak var myTableView          : UITableView!
    @IBOutlet weak var saveButton           : UIButton!
    @IBOutlet weak var sortAscendingLabel   : UILabel!
    @IBOutlet weak var sortAscendingSwitch  : UISwitch!
    @IBOutlet weak var titleLabel           : UILabel!
    
    
    
    // MARK: Private Variables

    private struct Constants {
        static let cellID = "SortOptionsTableViewCell"
    }

    private let navigatorCentral    = NavigatorCentral.sharedInstance
    private var originalOptionIndex = 0
    private var originalOptionTuple = ( "", true )
    private var selectedOptionIndex = 0
    private var somethingChanged    = false
    private let sortOptionNames     = [SortOptionNames.byFilename, SortOptionNames.byRelativePath]
    private let sortOptions         = [SortOptions.byFilename,     SortOptions.byRelativePath    ]
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        titleLabel        .text = NSLocalizedString( "Title.SelectSortOptions",   comment: "Select Sort Options" )
        sortAscendingLabel.text = NSLocalizedString( "ButtonTitle.SortAscending", comment: "Sort Ascending"      )
        
        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        saveButton  .setTitle( NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), for: .normal )
        
        saveButton.isHidden = !somethingChanged
        
        originalOptionTuple = navigatorCentral.sortDescriptor

        switch originalOptionTuple.0 {
        case SortOptions.byRelativePath:    selectedOptionIndex = 1
        default:                            selectedOptionIndex = 0    // byFilename
        }
        
        originalOptionIndex = selectedOptionIndex
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear(animated)
        
        sortAscendingSwitch.isOn = originalOptionTuple.1
        myTableView.reloadData()
    }
    
    
    
    //MARK: Target/Action Methods
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        logTrace()
        dismiss(animated: true)
    }
    
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        let sortAscendingFlag = sortAscendingSwitch.isOn
        let sortOption        = sortOptions[selectedOptionIndex]
        
        if ( sortAscendingFlag != originalOptionTuple.1 ) || ( sortOption != originalOptionTuple.0 ) {
            navigatorCentral.sortDescriptor = ( sortOption, sortAscendingFlag )
            
            delegate?.sortOptionsViewController( self, didSelectNewSortOption: true )
        }
        
        dismiss(animated: true)
    }
    
    
    @IBAction func sortAscendingSwitchValueChanged(_ sender: Any) {
        saveButton.isHidden = ( sortAscendingSwitch.isOn == originalOptionTuple.1 ) && ( originalOptionIndex == selectedOptionIndex )
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension SortOptionsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortOptionNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        cell.accessoryType   = ( indexPath.row == selectedOptionIndex ) ? .checkmark : .none
        cell.textLabel!.text = sortOptionNames[indexPath.row]
        
        return cell
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension SortOptionsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentSelectedCell = tableView.cellForRow(at: indexPath )
        let lastSelectedCell    = tableView.cellForRow(at: IndexPath(row: selectedOptionIndex, section: 0 ) )

        tableView.deselectRow(at: indexPath, animated: false )
        
        lastSelectedCell?   .accessoryType = .none
        currentSelectedCell?.accessoryType = .checkmark
        
        selectedOptionIndex = indexPath.row
        
        saveButton.isHidden = ( sortAscendingSwitch.isOn == originalOptionTuple.1 ) && ( originalOptionIndex == selectedOptionIndex )
    }
    
    
}
