//
//  NasLoginViewController.swift
//  WineStock
//
//  Created by Clint Shank on 3/2/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol NasLoginViewControllerDelegate : AnyObject {
    func nasLoginViewController(_ nasLoginViewController: NasLoginViewController, didAccept userName: String, and password: String )
}



class NasLoginViewController: UIViewController {
    
    // MARK: Public Variables

    weak var    delegate: NasLoginViewControllerDelegate!
    var         device  : SMBDevice!

    
    @IBOutlet weak var cancelButton      : UIButton!
    @IBOutlet weak var nasDriveNameLabel : UILabel!
    @IBOutlet weak var okButton          : UIButton!
    @IBOutlet weak var passwordLabel     : UILabel!
    @IBOutlet weak var passwordTextField : UITextField!
    @IBOutlet weak var titleLabel        : UILabel!
    @IBOutlet weak var userNameLabel     : UILabel!
    @IBOutlet weak var userNameTextField : UITextField!


    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        nasDriveNameLabel.text = ""
        passwordTextField.text = ""
        userNameTextField.text = ""
        
        passwordLabel.text = NSLocalizedString( "LabelText.Password",      comment: "Password"  )
        userNameLabel.text = NSLocalizedString( "LabelText.UserName",      comment: "User Name" )
        titleLabel   .text = NSLocalizedString( "Title.EnterCredentials",  comment: "Enter Credentials for" )
        
        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        okButton    .setTitle( NSLocalizedString( "ButtonTitle.OK",     comment: "OK"     ), for: .normal )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )

        nasDriveNameLabel.text = device.netbiosName
    }
    

    
    // MARK: Target/Action Methods
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        dismiss( animated: true, completion: nil )
   }
    
    
    @IBAction func okButtonTouched(_ sender: Any) {
        
        if let userName = userNameTextField.text, let password = passwordTextField.text {
            delegate.nasLoginViewController( self, didAccept: userName, and: password )
        }
        
        dismiss( animated: true, completion: nil )
    }
    
    
}
