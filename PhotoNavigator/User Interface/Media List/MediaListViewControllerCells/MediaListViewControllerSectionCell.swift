//
//  MediaListViewControllerSectionCell.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 5/20/24.
//

import UIKit


protocol MediaListViewControllerSectionCellDelegate: AnyObject {
    func mediaListViewControllerSectionCell(_ mediaListViewControllerSectionCell: MediaListViewControllerSectionCell, section: Int, isOpen: Bool )
}



class MediaListViewControllerSectionCell: UITableViewCell {

    
    // MARK: Public Variables
    
    @IBOutlet weak var titleLabel  : UILabel!
    @IBOutlet weak var toggleButton: UIButton!

    
    
    // MARK: Private Variables
    
    private var delegate            : MediaListViewControllerSectionCellDelegate!
    private let navigatorCentral    = NavigatorCentral.sharedInstance
    private var sectionIsOpen       = false
    private var sectionNumber       = 0

        
    
    // MARK: Cell Lifecycle Methods
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func toggleButtonTouched(_ sender: UIButton) {
        delegate.mediaListViewControllerSectionCell( self, section: sectionNumber, isOpen: sectionIsOpen )
    }

        
        
    // MARK: Public Initializer

    func initializeFor(_ section: Int, with titleText: String, isOpen: Bool, _ delegate: MediaListViewControllerSectionCellDelegate ) {
        self.delegate = delegate
        
        sectionIsOpen = isOpen
        sectionNumber = section
        
        titleLabel.text      = titleText
        titleLabel.textColor = .black
        
        toggleButton.setTitle( "", for: .normal )
    }

    

}
