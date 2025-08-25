//
//  UIKitExtensionsViewController.swift
//  WineStock
//
//  Created by Clint Shank on 1/3/20.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit


// MARK: UIViewController Methods


struct HeaderViewTagOffsets {
    static let down = 200
    static let up   = 100
}


extension UIViewController {
    
    func configureBackBarButtonItem() {
        let backBarButtonItem = UIBarButtonItem()
        
        backBarButtonItem.title = NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
        navigationController?.navigationBar.topItem?.backBarButtonItem = backBarButtonItem
    }

    
    func headerViewFor(_ tableView : UITableView, _ section : Int, with title : String, arrowUp : Bool ) -> UIView {
        // NOTE: This method is no longer used
        let     button     = UIButton.init( type: .system )
        let     tableWidth = tableView.frame.size.width
        let     headerView = UIView .init( frame: CGRect.init( x:  0, y:  0, width: tableWidth,      height: 44 ) )
        let     labelView  = UILabel.init( frame: CGRect.init( x: 10, y: 11, width: tableWidth - 40, height: 22 ) )

        button.setImage( UIImage( named: arrowUp ? "arrowUp" : "arrowDown" ), for: .normal )
        button.frame     = CGRect.init( x: tableWidth - 45, y: 7.0, width: 30.0, height: 30.0 )
        button.tag       = section + ( arrowUp ? HeaderViewTagOffsets.up : HeaderViewTagOffsets.down )
        button.tintColor = .blue

        headerView.backgroundColor = .lightGray
        
        labelView.text      = title
        labelView.textColor = .white
        
        headerView.addSubview( button )
        headerView.addSubview( labelView  )

        return headerView
    }
    
    
    func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
        logVerbose( "[ %@ ]", storyboardId )
        let     storyboardName = "Main_iPhone"
        let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
        let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
        
        
        return viewController
    }
    
    
    func presentAlert( title: String, message: String ) {
        logVerbose( "[ %@ ]\n    [ %@ ]", title, message )
        let         alert    = UIAlertController.init( title: title, message: message, preferredStyle: .alert )
        let         okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default, handler: nil )
        
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }

    
    func removeViewControllerByIdiom() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.popViewController( animated: true )
        }
        else {
            dismiss(animated: true )
        }

    }

    
    func runningInSimulator() -> Bool {
        var     simulator = false

        #if targetEnvironment(simulator)
        simulator = true
        #endif
        
        return simulator
    }
    
    
    func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
        logVerbose( "[ %@ ]", storyboardId )
        let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
        let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
        let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
        
        return viewController
    }
    
    
    
    // MARK: UserDefaults Convenience Methods
    
    func getIntValueFromUserDefaults(_ key: String ) -> Int {
        return UserDefaults.standard.integer(forKey: key )
    }
    
    
    func getStringFromUserDefaults(_ key: String ) -> String {
        var savedString = ""
        
        if let string = UserDefaults.standard.string( forKey: key ) {
            savedString = string
        }

        return savedString
    }
    
    
    func flagIsPresentInUserDefaults(_ key : String ) -> Bool {
        var     flagIsPresent = false
        
        if let _ = UserDefaults.standard.string( forKey: key ) {
            flagIsPresent = true
        }
        
        return flagIsPresent
    }
    
    
    func removeFlagFromUserDefaults(_ key: String ) {
        UserDefaults.standard.removeObject(forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func saveFlagInUserDefaults(_ key: String ) {
        UserDefaults.standard.set( key, forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func saveShowFlagInUserDefaults(_ key: String ) {
        let     calendar    = Calendar.current
        let     today       = calendar.component( .day, from: Date() )
        let     todayString = String( format: "%d", today )
        
        UserDefaults.standard.set( todayString, forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func saveStringToUserDefaults(_ value: String, for key: String ) {
        UserDefaults.standard.removeObject( forKey: key )
        UserDefaults.standard.set( value,   forKey: key )
        
        UserDefaults.standard.synchronize()
    }
    
    
    func setIntValueInUserDefaults(_ value: Int, _ key: String ) {
        UserDefaults.standard.set( value, forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func showFlagFromUserDefaults(_ key : String ) -> Bool {
        let     calendar    = Calendar.current
        let     today       = calendar.component( .day, from: Date() )
        let     todayString = String( format: "%d", today )
        let     lastViewed  = UserDefaults.standard.string( forKey: key )
        
        return ( lastViewed != todayString )
    }

    
}



// MARK: Image Methods

extension UIImage {
    
    func resized( withPercentage percentage: CGFloat, isOpaque: Bool = true ) -> UIImage? {
        let canvas = CGSize( width: size.width * percentage, height: size.height * percentage )
        let format = imageRendererFormat
        
        format.opaque = isOpaque
        
        return UIGraphicsImageRenderer( size: canvas, format: format ).image {
            _ in
            
            draw( in: CGRect( origin: .zero, size: canvas ) )
        }
        
    }
    
    
    func resized( toWidth width: CGFloat, isOpaque: Bool = true ) -> UIImage? {
        let canvas = CGSize( width: width, height: CGFloat( ceil( width/size.width * size.height ) ) )
        let format = imageRendererFormat
        
        format.opaque = isOpaque
        
        return UIGraphicsImageRenderer( size: canvas, format: format ).image {
            _ in
            
            draw( in: CGRect( origin: .zero, size: canvas ) )
        }
        
    }
    
    
}
    


// MARK: String Methods

extension String {
    
    func heightWithConstrainedWidth( width: CGFloat, font: UIFont ) -> CGFloat {
        let constraintRect = CGSize( width: width, height: .greatestFiniteMagnitude )
        let boundingBox    = self.boundingRect( with        : constraintRect,
                                                options     : [.usesLineFragmentOrigin, .usesFontLeading],
                                                attributes  : [NSAttributedString.Key.font: font],
                                                context     : nil)
        return boundingBox.height
    }
    
    
}



// MARK: Global Methods

func extensionFrom(_ filename: String ) -> String {
    var fileExtension = ""
    
    let filenameComponents = filename.components(separatedBy: GlobalConstants.fileExtensionSeparator )
    
    if filenameComponents.count >= 2 {
        fileExtension = filenameComponents.last!
    }

    return fileExtension.uppercased()
}


func stringFor(_ boolValue: Bool ) -> String {
    return ( boolValue ? "true" : "false" )
}


func stringFor(_ date: Date ) -> String {
    let     calendar = Calendar.current
    let     year     = calendar.component( .year,  from: date )
    let     month    = calendar.component( .month, from: date )
    let     day      = calendar.component( .day,   from: date )
    
    return String( format: "%4d-%02d-%02d", year, month, day )
}


func stringFor(_ decimalValue : NSDecimalNumber, withCurrentSymbol : Bool ) -> String {
    var     amountString = ""
    let     formatter    = NumberFormatter()
    
    formatter.locale      = .current
    formatter.numberStyle = withCurrentSymbol ? .currency : .decimal
    
    if let string = formatter.string( from: decimalValue ) {
        amountString = string
    }
    
    return amountString
}


func stringFor(_ frame: CGRect ) -> String {
    return String( format: "[ %4.1f, %4.1f ][ %4.1f, %4.1f ]", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height )
}


func stringFor(_ size: CGSize ) -> String {
    return String( format: "[ %4.1f, %4.1f ]", size.width, size.height )
}


func indexPathFrom(_ string: String ) -> IndexPath {
    let components = string.components(separatedBy: "," )
    var indexPath  = GlobalIndexPaths.noSelection

    if components.count == 2 {
        let trimmedComponents = components.map {
            $0.trimmingCharacters( in: .whitespaces )
        }
        
        indexPath = IndexPath(row: Int( trimmedComponents[1] )!, section: Int( trimmedComponents[0] )! )
    }
    
    return indexPath
}


func stringFor(_ indexPath: IndexPath ) -> String {
    return String( format: "%d, %d", indexPath.section, indexPath.row )
}


