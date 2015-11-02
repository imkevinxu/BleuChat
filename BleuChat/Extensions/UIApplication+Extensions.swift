//
//  UIApplication+Extensions.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit

// MARK: - Singletons

extension UIApplication {

    class var APP_VERSION: String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    }

    class var APP_BUILD: String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
    }
}

// MARK: - Helper Methods

extension UIApplication {

    class func applicationState() -> String {
        switch sharedApplication().applicationState {
            case .Active:
                return "Active"
            case .Inactive:
                return "Inactive"
            case .Background:
                return "Background"
        }
    }
}