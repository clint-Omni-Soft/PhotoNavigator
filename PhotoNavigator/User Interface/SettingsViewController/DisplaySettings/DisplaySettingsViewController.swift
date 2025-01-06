//
//  DisplaySettingsViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 9/5/24.
//


import UIKit



class DisplaySettingsViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var imageDurationLabel : UILabel!
    @IBOutlet weak var imageDurationSlider: UISlider!
    
    
    
    
    // MARK: Private Variables
    
    private struct CellIDs {
        static let basic = "DisplaySettingsViewControllerCell"
    }
    
    private let navigatorCentral = NavigatorCentral.sharedInstance
    private var originalDuration = 0

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString( "Title.DisplaySettings", comment: "Display Settings" )
        configureBackBarButtonItem()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear(animated)
        originalDuration = navigatorCentral.imageDuration
        
        imageDurationLabel.text = NSLocalizedString( "LabelText.ImageDuration", comment: "Image Duration" ) + String( format: " - %d sec", originalDuration )

        imageDurationSlider.minimumValue = 0.0
        imageDurationSlider.maximumValue = 100.0
        imageDurationSlider.value        = Float( originalDuration )
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        
        let newDuration = Int( imageDurationSlider.value )
        
        if newDuration != originalDuration {
            navigatorCentral.imageDuration = newDuration
        }
        
    }
    


    // MARK: Target/Action Methods
    
    @IBAction func imageDurationSliderValueChanged(_ sender: UISlider) {
        imageDurationLabel.text = NSLocalizedString( "LabelText.ImageDuration", comment: "Image Duration" ) + String( format: " - %d sec", Int( sender.value ) )
    }
    
    
}
