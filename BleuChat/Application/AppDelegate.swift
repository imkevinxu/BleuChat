//
//  AppDelegate.swift
//  BleuChat
//
//  Created by Kevin Xu on 10/25/15
//  Copyright (c) 2015 Kevin Xu. All rights reserved.
//

import UIKit

// MARK: - Properties

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
}

// MARK: - Application Lifecycle

extension AppDelegate {

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        setupApplication()
        return true
    }
    
    // MARK: Setup Methods
    
    private func setupApplication() {

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if let window = window {
            window.rootViewController = BCMainViewController()
            window.makeKeyAndVisible()
        }
    }
}
