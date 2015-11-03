//
//  BCDefaults.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation

// MARK: - Properties

struct BCDefaults {

    enum Keys: String {
        case Name     = "com.bleuchat.Name"
        case Messages = "com.bleuchat.Messages"
    }

    // MARK: Singleton

    static let TheUserDefaults = NSUserDefaults.standardUserDefaults()
}

// MARK: - Methods

extension BCDefaults {

    // MARK: Get Methods

    static func arrayForKey(key: Keys) -> [AnyObject]? {
        return TheUserDefaults.arrayForKey(key.rawValue)
    }

    static func boolForKey(key: Keys) -> Bool {
        return TheUserDefaults.boolForKey(key.rawValue)
    }

    static func dataForKey(key: Keys) -> NSData? {
        return TheUserDefaults.dataForKey(key.rawValue)
    }

    static func dictionaryForKey(key: Keys) -> [String : AnyObject]? {
        return TheUserDefaults.dictionaryForKey(key.rawValue)
    }

    static func floatForKey(key: Keys) -> Float {
        return TheUserDefaults.floatForKey(key.rawValue)
    }

    static func integerForKey(key: Keys) -> Int {
        return TheUserDefaults.integerForKey(key.rawValue)
    }

    static func stringArrayForKey(key: Keys) -> [String]? {
        return TheUserDefaults.stringArrayForKey(key.rawValue)
    }

    static func stringForKey(key: Keys) -> String? {
        return TheUserDefaults.stringForKey(key.rawValue)
    }

    static func objectForKey(key: Keys) -> AnyObject? {
        return TheUserDefaults.objectForKey(key.rawValue)
    }

    static func dataObjectForKey<T>(key: Keys) -> T? {
        if let data = objectForKey(key) as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! T?
        } else {
            return nil
        }
    }

    static func dataObjectArrayForKey<T>(key: Keys) -> [T]? {
        if let data = objectForKey(key) as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [T]?
        } else {
            return nil
        }
    }

    // MARK: Set Methods

    static func setBool(value: Bool, forKey key: Keys) {
        TheUserDefaults.setBool(value, forKey: key.rawValue)
        TheUserDefaults.synchronize()
    }

    static func setFloat(value: Float, forKey key: Keys) {
        TheUserDefaults.setFloat(value, forKey: key.rawValue)
        TheUserDefaults.synchronize()
    }

    static func setInteger(value: Int, forKey key: Keys) {
        TheUserDefaults.setInteger(value, forKey: key.rawValue)
        TheUserDefaults.synchronize()
    }

    static func setValue(value: NSURL?, forKey key: Keys) {
        TheUserDefaults.setValue(value, forKey: key.rawValue)
        TheUserDefaults.synchronize()
    }

    static func setObject(value: AnyObject?, forKey key: Keys) {
        TheUserDefaults.setObject(value, forKey: key.rawValue)
        TheUserDefaults.synchronize()
    }

    static func setDataObject(object: AnyObject?, forKey key: Keys) {
        if let object: AnyObject = object {
            setObject(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
        } else {
            setObject(nil, forKey: key)
        }
    }

    static func appendDataObjectToArray(object: AnyObject?, forKey key: Keys) {
        if let object: AnyObject = object {
            if var objectArray: [AnyObject] = dataObjectArrayForKey(key) {
                objectArray.append(object)
                setObject(NSKeyedArchiver.archivedDataWithRootObject(objectArray), forKey: key)
            } else {
                setObject(NSKeyedArchiver.archivedDataWithRootObject([object]), forKey: key)
            }
        } else {
            setObject(nil, forKey: key)
        }
    }

    // MARK: Remove Methods

    static func removeObjectForKey(key: Keys) {
        TheUserDefaults.removeObjectForKey(key.rawValue)
        TheUserDefaults.synchronize()
    }

    static func resetDefaults() {
        if let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier {
            TheUserDefaults.removePersistentDomainForName(bundleIdentifier)
        }
    }
}