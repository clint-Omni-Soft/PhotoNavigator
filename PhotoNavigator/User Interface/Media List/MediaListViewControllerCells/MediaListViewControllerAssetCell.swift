//
//  MediaListViewControllerAssetCell.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 9/14/24.
//

import UIKit
import Photos



class MediaListViewControllerAssetCell: UITableViewCell {

    
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var titleLabel : UILabel!
    
    
    // MARK: Private Variables
    
    struct Constants {
        static let imageSize = CGSize(width: 40.0, height: 40.0 )
    }
    
    private let navigatorCentral = NavigatorCentral.sharedInstance
    private let imageManager     = PHImageManager.default()

    
    
    // MARK: UITableViewCell Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith(_ asset: PHAsset, _ accessory: UITableViewCell.AccessoryType ) {
        myImageView.image = UIImage( named: GlobalConstants.noImage )
        titleLabel .text  = asset.descriptorString()
        accessoryType     = accessory

        imageManager.requestImage(for: asset, targetSize: Constants.imageSize, contentMode: .aspectFill, options: nil) { image, infoDictionary in
            if image != nil {
                self.myImageView.image = image
            }
            
        }
        
    }
    
    
}
