//
//  BCDevice.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit
import GBDeviceInfo

// MARK: - Singletons

struct BCDevice {

    static let TheCurrentDevice = UIDevice.currentDevice()
    static let TheCurrentVersion = (UIDevice.currentDevice().systemVersion as NSString).floatValue
    static let TheCurrentHeight = UIScreen.mainScreen().bounds.size.height
    static let TheCurrentOrientation = UIApplication.sharedApplication().statusBarOrientation
}

// MARK: - Device Idiom Checks

extension BCDevice {

    // MARK: Constants

    static let PHONE_OR_PAD = BCDevice.phoneOrPad()
    static let SIMULATOR_OR_DEVICE = BCDevice.simulatorOrDevice()
    static let CONFIGURATION = BCDevice.configuration()
    static let CURRENT_DEVICE = GBDeviceInfo.deviceInfo().modelString

    // MARK: Boolean Checks

    static func isPhone() -> Bool {
        return TheCurrentDevice.userInterfaceIdiom == .Phone
    }

    static func isPad() -> Bool {
        return TheCurrentDevice.userInterfaceIdiom == .Pad
    }

    static func isSimulator() -> Bool {
        return SIMULATOR_OR_DEVICE == "Simulator"
    }

    static func isDevice() -> Bool {
        return SIMULATOR_OR_DEVICE == "Device"
    }

    static func isDebug() -> Bool {
        return CONFIGURATION == "Debug"
    }

    static func isRelease() -> Bool {
        return CONFIGURATION == "Release"
    }

    static func isPortrait() -> Bool {
        return TheCurrentOrientation == .Portrait
    }

    static func isLandscape() -> Bool {
        return TheCurrentOrientation == .LandscapeLeft || TheCurrentOrientation == .LandscapeRight
    }

    static func isUpsideDown() -> Bool {
        return TheCurrentOrientation == .PortraitUpsideDown
    }

    // MARK: Helper Methods

    private static func phoneOrPad() -> String {
        if isPhone() {
            return "iPhone"
        } else if isPad() {
            return "iPad"
        }
        return "Not iPhone nor iPad"
    }

    private static func simulatorOrDevice() -> String {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return "Simulator"
        #else
            return "Device"
        #endif
    }

    private static func configuration() -> String {
        #if DEBUG
            return "Debug"
        #else
            return "Release"
        #endif
    }
}

// MARK: - Device Version Checks

extension BCDevice {

    enum Versions: Float {
        case Five  = 5.0
        case Six   = 6.0
        case Seven = 7.0
        case Eight = 8.0
        case Nine  = 9.0
    }

    static func isVersion(version: Versions) -> Bool {
        return TheCurrentVersion >= version.rawValue && TheCurrentVersion < (version.rawValue + 1.0)
    }

    static func isVersionOrLater(version: Versions) -> Bool {
        return TheCurrentVersion >= version.rawValue
    }

    static func isVersionOrEarlier(version: Versions) -> Bool {
        return TheCurrentVersion < (version.rawValue + 1.0)
    }

    static let CURRENT_VERSION = "\(TheCurrentVersion)"

    // MARK: iOS 5 Checks

    static func IS_OS_5() -> Bool {
        return isVersion(.Five)
    }

    static func IS_OS_5_OR_LATER() -> Bool {
        return isVersionOrLater(.Five)
    }

    static func IS_OS_5_OR_EARLIER() -> Bool {
        return isVersionOrEarlier(.Five)
    }

    // MARK: iOS 6 Checks

    static func IS_OS_6() -> Bool {
        return isVersion(.Six)
    }

    static func IS_OS_6_OR_LATER() -> Bool {
        return isVersionOrLater(.Six)
    }

    static func IS_OS_6_OR_EARLIER() -> Bool {
        return isVersionOrEarlier(.Six)
    }

    // MARK: iOS 7 Checks

    static func IS_OS_7() -> Bool {
        return isVersion(.Seven)
    }

    static func IS_OS_7_OR_LATER() -> Bool {
        return isVersionOrLater(.Seven)
    }

    static func IS_OS_7_OR_EARLIER() -> Bool {
        return isVersionOrEarlier(.Seven)
    }

    // MARK: iOS 8 Checks

    static func IS_OS_8() -> Bool {
        return isVersion(.Eight)
    }

    static func IS_OS_8_OR_LATER() -> Bool {
        return isVersionOrLater(.Eight)
    }

    static func IS_OS_8_OR_EARLIER() -> Bool {
        return isVersionOrEarlier(.Eight)
    }

    // MARK: iOS 9 Checks

    static func IS_OS_9() -> Bool {
        return isVersion(.Nine)
    }

    static func IS_OS_9_OR_LATER() -> Bool {
        return isVersionOrLater(.Nine)
    }

    static func IS_OS_9_OR_EARLIER() -> Bool {
        return isVersionOrEarlier(.Nine)
    }
}

// MARK: - Device Size Checks

extension BCDevice {

    enum Heights: CGFloat {
        case Inches_3_5 = 480
        case Inches_4   = 568
        case Inches_4_7 = 667
        case Inches_5_5 = 736
    }

    static func isSize(height: Heights) -> Bool {
        return TheCurrentHeight == height.rawValue
    }

    static func isSizeOrLarger(height: Heights) -> Bool {
        return TheCurrentHeight >= height.rawValue
    }

    static func isSizeOrSmaller(height: Heights) -> Bool {
        return TheCurrentHeight <= height.rawValue
    }

    static let CURRENT_SIZE = BCDevice.currentSize()

    private static func currentSize() -> String {
        if IS_3_5_INCHES() {
            return "3.5 Inches"
        } else if IS_4_INCHES() {
            return "4 Inches"
        } else if IS_4_7_INCHES() {
            return "4.7 Inches"
        } else if IS_5_5_INCHES() {
            return "5.5 Inches"
        }
        return "\(TheCurrentHeight) Points"
    }

    // MARK: Retina Check

    static func IS_RETINA() -> Bool {
        return UIScreen.mainScreen().respondsToSelector("scale")
    }

    // MARK: 3.5 Inch Checks

    static func IS_3_5_INCHES() -> Bool {
        return isPhone() && isSize(.Inches_3_5)
    }

    static func IS_3_5_INCHES_OR_LARGER() -> Bool {
        return isPhone() && isSizeOrLarger(.Inches_3_5)
    }

    static func IS_3_5_INCHES_OR_SMALLER() -> Bool {
        return isPhone() && isSizeOrSmaller(.Inches_3_5)
    }

    // MARK: 4 Inch Checks

    static func IS_4_INCHES() -> Bool {
        return isPhone() && isSize(.Inches_4)
    }

    static func IS_4_INCHES_OR_LARGER() -> Bool {
        return isPhone() && isSizeOrLarger(.Inches_4)
    }

    static func IS_4_INCHES_OR_SMALLER() -> Bool {
        return isPhone() && isSizeOrSmaller(.Inches_4)
    }

    // MARK: 4.7 Inch Checks

    static func IS_4_7_INCHES() -> Bool {
        return isPhone() && isSize(.Inches_4_7)
    }

    static func IS_4_7_INCHES_OR_LARGER() -> Bool {
        return isPhone() && isSizeOrLarger(.Inches_4_7)
    }

    static func IS_4_7_INCHES_OR_SMALLER() -> Bool {
        return isPhone() && isSizeOrLarger(.Inches_4_7)
    }

    // MARK: 5.5 Inch Checks

    static func IS_5_5_INCHES() -> Bool {
        return isPhone() && isSize(.Inches_5_5)
    }
    
    static func IS_5_5_INCHES_OR_LARGER() -> Bool {
        return isPhone() && isSizeOrLarger(.Inches_5_5)
    }
    
    static func IS_5_5_INCHES_OR_SMALLER() -> Bool {
        return isPhone() && isSizeOrLarger(.Inches_5_5)
    }
}