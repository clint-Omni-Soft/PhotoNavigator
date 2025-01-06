//
//  MediaListViewControllerCell.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 5/20/24.
//


import UIKit



class MediaListViewControllerCell: UITableViewCell {
    
    
    // MARK: Private Variables
    
    private let navigatorCentral = NavigatorCentral.sharedInstance

    
    
    // MARK: UITableViewCell Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected( false, animated: animated)
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith(_ mediaFile: MediaFile, _ accessory: UITableViewCell.AccessoryType ) {
        textLabel?.text    = mediaFile.filename
        self.accessoryType = accessory
    }

    
    
    // MARK: Utility Methods
    
}
