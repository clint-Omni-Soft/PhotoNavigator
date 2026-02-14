//
//  UIKitExtensionsViewController.swift
//  WineStock
//
//  Created by Clint Shank on 1/3/20.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



struct HeaderViewTagOffsets {
    static let down = 200
    static let up   = 100
}



// MARK: Date Methods

extension Date {
    
    func daysBetweenDate(toDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: toDate)
        return components.day ?? 0
    }
    
    
}



// MARK: UIViewController Methods

extension UIViewController {
    
    func configureBackBarButtonItem() {
        let backBarButtonItem = UIBarButtonItem()
        
        backBarButtonItem.title = NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
        navigationController?.navigationBar.topItem?.backBarButtonItem = backBarButtonItem
    }

    
    func configureNavBarTitleButtonWith(_ title: String, _ ibAction: Selector ) {
        let containerView  = UIView.init( frame: CGRect( x: 0, y: 0, width: 160, height: 40 ) )
        let navTitleButton = UIButton( type: .custom )

        navTitleButton.tag = 111
        navTitleButton.frame = containerView.frame
        navTitleButton.setTitle( title, for: .normal )
        navTitleButton.setTitleColor( .blue, for: .normal )
        navTitleButton.titleLabel?.font = UIFont.boldSystemFont( ofSize: 18 )
        navTitleButton.addTarget( self, action:  ibAction, for: .touchUpInside )
        
        containerView.addSubview( navTitleButton )
        
        navigationController?.navigationBar.tintColor = .blue
        navigationItem.titleView = containerView
    }
    
    
    func customizeButton(_ button: UIButton, with title: String ) {
        button.layer.borderColor   = UIColor.black.cgColor
        button.layer.borderWidth   = 1.0
        button.layer.cornerRadius  = 15.0
        button.layer.masksToBounds = true
        
        button.setTitle( title, for: .normal )

        if #available( iOS 26.0, *) {
            button.configuration = .glass()
        }
        
    }
    
    
    func getNavBarTitleButton() -> UIButton {
        var button = UIButton(frame: CGRect( x: 0, y: 0, width: 160, height: 40 ) )
        
        if let titleView = navigationItem.titleView {
            button = titleView.viewWithTag( 111 ) as! UIButton
        }
        
        return button
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

    
    func prominentStyleForBarButtonItem() -> UIBarButtonItem.Style {
        var style = UIBarButtonItem.Style.plain
        
        if #available(iOS 26.0, *) {
            style = .prominent
        }

        return style
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
    
    func flagIsPresentInUserDefaults(_ key : String ) -> Bool {
        var     flagIsPresent = false
        
        if let _ = UserDefaults.standard.string( forKey: key ) {
            flagIsPresent = true
        }
        
        return flagIsPresent
    }
    
    
    func getIndexPathFromUserDefaults(_ key: String ) -> IndexPath {
        var indexPath = GlobalIndexPaths.noSelection
        
        if let value = UserDefaults.standard.string( forKey: key ) {
            let components = value.components(separatedBy: "/" )
            let section    = Int( components[0] ) ?? 0
            let row        = Int( components[1] ) ?? 0
            
            indexPath = IndexPath(row: row, section: section )
        }

        return indexPath
    }
    
    
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
    
    
    func removeFlagFromUserDefaults(_ key: String ) {
        UserDefaults.standard.removeObject(forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func removeStringFromUserDefaults(_ key: String ) {
        UserDefaults.standard.removeObject(forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func saveFlagInUserDefaults(_ key: String ) {
        UserDefaults.standard.set( key, forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func saveIndexPathInUserDefaults(_ key: String, indexPath: IndexPath ) {
        let value = String(format:  "%d/%d", indexPath.section, indexPath.row )
        
        UserDefaults.standard.set( value, forKey: key )
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



// MARK: String Methods

extension String {
    
    var alphaNumeric: String {
            return components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        }
    
    
    func heightWithConstrainedWidth( width: CGFloat, font: UIFont ) -> CGFloat {
        let constraintRect = CGSize( width: width, height: .greatestFiniteMagnitude )
        let boundingBox    = self.boundingRect( with        : constraintRect,
                                                options     : [.usesLineFragmentOrigin, .usesFontLeading],
                                                attributes  : [NSAttributedString.Key.font: font],
                                                context     : nil)
        return boundingBox.height
    }
    
    
}



// MARK: Image Methods

extension UIImage {
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
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



// MARK: Custom Presentation Classes

class CustomPresentationController: UIPresentationController {

    var customFrame: CGRect!

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, customFrame: CGRect) {
        self.customFrame = customFrame
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return customFrame
    }

    override func presentationTransitionWillBegin() {
        // Optional: Add a dimming view or other custom animations here
    }

    override func dismissalTransitionWillBegin() {
        // Optional: Add dismissal animations here
    }

}



class CustomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    var customFrame: CGRect!

    init(_ customFrame: CGRect) {
        self.customFrame = customFrame
        super.init()
    }

    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting, customFrame: customFrame)
    }
    
    
}



// MARK: Global Methods

func dateFrom(_ dateString: String ) -> Date {
    let     dateComponentArray = dateString.components(separatedBy: "-" )
    var     date = Date.distantFuture
    
    if dateComponentArray.count == 3 {
        let     formatter = DateFormatter()
        
        formatter.locale     = .current
        formatter.dateFormat = "yyyy-MM-dd"
        
        date = formatter.date(from: dateString)!
    }
    
    return date
}


func dayOfTheWeekFrom(_ date: Date ) -> Int {
    if let oneBasedDay = Calendar.current.dateComponents( [.weekday], from: date ).weekday {
        return oneBasedDay - 1
    }

    logTrace( "ERROR!!!  Unable to unwrap date!  Returning 0" )
    return  0
}


func extensionFrom(_ filename: String ) -> String {
    var fileExtension = ""
    
    let filenameComponents = filename.components(separatedBy: GlobalConstants.fileExtensionSeparator )
    
    if filenameComponents.count >= 2 {
        fileExtension = filenameComponents.last!
    }

    return fileExtension.uppercased()
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


func stringFor(_ indexPath: IndexPath ) -> String {
    return String( format: "%d, %d", indexPath.section, indexPath.row )
}


func stringFor(_ rect: CGRect ) -> String {
    return String( format: "[ %3.1f, %3.1f ][ %3.1f, %3.1f ]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height )
}


func stringFor(_ size: CGSize ) -> String {
    return String( format: "[ %3.1f, %3.1f ]", size.width, size.height )
}


