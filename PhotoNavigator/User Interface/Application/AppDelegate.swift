//
//  AppDelegate.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/5/24.
//

import UIKit

@UIApplicationMain



class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Public Definitions
    var hidePrimary        = false
    var mediaViewer        : MediaViewerViewController!
    var splitViewController: UISplitViewController!
    var window             : UIWindow?
    
    
    // MARK: Private Definitions
    private let navigatorCentral   = NavigatorCentral.sharedInstance
    private let notificationCenter = NotificationCenter.default
    
    var activeWindow: UIWindow? {
        get {
            var myWindow = window
            
            if myWindow == nil {
                let sceneDelegate = (UIApplication.shared.connectedScenes.first as? UIWindowScene)!.delegate as! SceneDelegate
                myWindow = sceneDelegate.window
            }
            
            return myWindow
        }
        
    }

    
    
    // MARK: UIApplication Lifecycle Methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        LogCentral.sharedInstance.setupLogging()
        logTrace()
        
        if #available(iOS 15, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0.0
        }
        
        return true
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        logTrace()
        if navigatorCentral.dataStoreLocation != .device {
            showPleaseWaitScreen()
        }

        navigatorCentral.enteringForeground()
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        logTrace()
        navigatorCentral.enteringBackground()
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        logTrace()
        navigatorCentral.enteringBackground()
    }

    
    
    // MARK: Public Interfaces

    func configureSplitViewController() {
        logTrace()
        if haveLinkToSplitViewController() {
            splitViewController.presentsWithGesture = false
            
            let minimumWidth = min( CGRectGetWidth( splitViewController.view.bounds ), CGRectGetHeight( splitViewController.view.bounds ) )
            
            splitViewController.minimumPrimaryColumnWidth = minimumWidth / 2
            splitViewController.maximumPrimaryColumnWidth = minimumWidth;
        }

    }

    
    func hidePrimaryView(_ isHidden: Bool ) {
        if haveLinkToSplitViewController() {
            hidePrimary = isHidden

            UIView.animate(withDuration: 0.5 ) { () -> Void in
                self.splitViewController?.preferredDisplayMode = self.hidePrimary ? UISplitViewController.DisplayMode.secondaryOnly : UISplitViewController.DisplayMode.oneBesideSecondary
            }
            
            if self.mediaViewer != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                    self.mediaViewer.primaryWindow( isHidden )
                }
                
            }
            
        }
       
    }
    
    
    func primaryIsHidden() -> Bool {
        var isHidden = true
        
        if haveLinkToSplitViewController() {
            isHidden = splitViewController.isCollapsed
        }

        return isHidden
    }
    
    
    func switchToMainApp() {
        let     storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        let     storyboard     = UIStoryboard(name: storyboardName, bundle: .main )

        logVerbose( "[ %@ ]", storyboardName )
        splitViewController = nil
        navigatorCentral.didOpenDatabase = false
        
        if let initialViewController = storyboard.instantiateInitialViewController() {
            navigatorCentral.pleaseWaiting = false

            activeWindow?.rootViewController = initialViewController
            activeWindow?.makeKeyAndVisible()
        }
        else {
            logTrace( "ERROR!!!!  Unable to instantiate initial view controller!" )
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func haveLinkToSplitViewController() -> Bool {
        var foundIt = true
        
        if splitViewController == nil {
            if let splitVC = self.activeWindow?.rootViewController as? UISplitViewController {
                splitViewController = splitVC
            }
            else {
                foundIt = false
                logVerbose( "NOT instantiated!" )
            }

        }
        
        return foundIt
    }
    
    
    private func showPleaseWaitScreen() {
        logTrace()
        let storyboard = UIStoryboard(name: "PleaseWait", bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            navigatorCentral.pleaseWaiting = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.activeWindow?.rootViewController = initialViewController
                self.activeWindow?.makeKeyAndVisible()
            }

        }

    }

    
}



// MARK: NavigatorCentralDelegate Methods

extension AppDelegate: NavigatorCentralDelegate {
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
//            navigatorCentral.reloadData( self )
        }
        
    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadMediaData: Bool ) {
        logTrace()

        if navigatorCentral.dataStoreLocation == .device {
            if .pad == UIDevice.current.userInterfaceIdiom {
                logTrace( "Posting mediaReloaded" )
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.mediaDataReloaded ), object: self )
            }

        }

        logTrace( "Posting ready" )
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
    

}

