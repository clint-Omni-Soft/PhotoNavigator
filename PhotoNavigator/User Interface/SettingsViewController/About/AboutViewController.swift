//
//  AboutViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 4/30/24.
//

import UIKit



class AboutViewController: UIViewController {

    
    // MARK: Public Variables
    
    @IBOutlet weak var versionLabel: UILabel!

    
    
    // MARK: Private Variables
    
    private struct StoryboardId {
        static let logViewer = "LogViewController"
    }

    
    
    // MARK: UIViewController Lifecycle Methods

    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.About",  comment: "About"   )
        configureBackBarButtonItem()
        
        var     labelText = ""
        
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            labelText = version
        }
        
        versionLabel.isHidden = labelText.isEmpty
        versionLabel.text     = "v" + labelText
    }
    

    
    // MARK: Target / Action Methods
    
    @IBAction func invisibleButtonTouched(_ sender: UIButton) {
        guard let logVC: LogViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardId.logViewer ) as? LogViewController else {
            logTrace( "ERROR: Could NOT load LogViewController!" )
            return
        }
        
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad {
            let navigationController = UINavigationController(rootViewController: logVC )
            
            navigationController.modalPresentationStyle = .fullScreen
            
            present( navigationController, animated: true, completion: nil )
        }
        else {
            navigationController?.pushViewController( logVC, animated: true )
        }

    }
    
    
}
