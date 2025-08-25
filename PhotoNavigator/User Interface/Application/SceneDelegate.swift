//
//  SceneDelegate.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 7/7/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: Public Definitions
    var window: UIWindow?
    
    
    // MARK: Private Definitions
    private let navigatorCentral = NavigatorCentral.sharedInstance

    

    // MARK: UIWindowSceneDelegate Lifecycle Methods
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let _ = (scene as? UIWindowScene) else {
            logVerbose( "Provided scene is NOT a UIWindowScene [ %@ ]!", session.configuration.name ?? "Unknown" )
            return
        }
        
    }

    
    func sceneWillEnterForeground(_ scene: UIScene) {
        logTrace()
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        logTrace()
        let deviceMainStoryboard = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        
        launchWindowFrom( ( navigatorCentral.dataStoreLocation != .device ) ? "PleaseWait" : deviceMainStoryboard )
        navigatorCentral.enteringForeground()
    }

    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        logTrace()
        navigatorCentral.enteringBackground()
    }
    
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    
    
    // MARK: Private Methods

    private func launchWindowFrom(_ storyboardName: String ) {
        logVerbose( "[ %@ ]", storyboardName )
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
        
    }


}

