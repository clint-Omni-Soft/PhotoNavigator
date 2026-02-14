//
//  LogViewController.swift
//  ClubLengths
//
//  Created by Clint Shank on 2/20/23.
//

import UIKit


class LogViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myTextView: UITextView!

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString( "Title.LogViewer", comment: "Log Viewer" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        myTextView.layoutManager.allowsNonContiguousLayout = false
        myTextView.text = logContents()
        
        loadBarButtonItems()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.myTextView.scrollRangeToVisible( NSRange( location: self.myTextView.text.count - 1, length: 1 ) )
        })

    }
    
    

    // MARK: Target / Action Methods
    
    @IBAction func leftBarButtonTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad {
            dismiss(animated: true )
        }
        else {
            navigationController?.popViewController( animated: true )
        }
        
    }

    

    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        if #available(iOS 26.0, *)  {
            navigationItem.leftBarButtonItem = UIBarButtonItem( image: UIImage(systemName: "checkmark"), style: .prominent, target: self, action: #selector( leftBarButtonTouched ) )
        }
        else {
            let title = ( ( UIDevice.current.userInterfaceIdiom == .pad ) ? NSLocalizedString( "ButtonTitle.Done", comment: "Done" ) : NSLocalizedString( "ButtonTitle.Back", comment: "Back" ) )
            
            navigationItem.leftBarButtonItem = UIBarButtonItem.init( title: title, style : prominentStyleForBarButtonItem(), target: self, action: #selector( leftBarButtonTouched(_:) ) )
        }
        
    }

    
}
