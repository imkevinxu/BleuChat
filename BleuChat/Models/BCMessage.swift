//
//  BCMessage.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Properties

final class BCMessage: NSObject, NSCoding {

    var message: String
    var name: String
    var isSelf: Bool
    var timestamp: NSDate
    var peripheralID: NSUUID?

    // MARK: Description

    override var description: String {
        return "\(name): \(message)"
    }

    // MARK: Initializers

    init(message: String, name: String, isSelf: Bool = false, timestamp: NSDate = NSDate(), peripheralID: NSUUID? = nil) {
        self.message = message
        self.name = name
        self.isSelf = isSelf
        self.timestamp = timestamp
        self.peripheralID = peripheralID
    }

    // MARK: - Delegates

    // MARK: NSCoding

    required convenience init?(coder decoder: NSCoder) {
        guard let message = decoder.decodeObjectForKey("message") as? String,
                  name = decoder.decodeObjectForKey("name") as? String,
                  timestamp = decoder.decodeObjectForKey("timestamp") as? NSDate
            else { return nil }

        self.init(
            message: message,
            name: name,
            isSelf: decoder.decodeBoolForKey("isSelf"),
            timestamp: timestamp,
            peripheralID: decoder.decodeObjectForKey("peripheralID") as? NSUUID
        )
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(message, forKey: "message")
        coder.encodeObject(name, forKey: "name")
        coder.encodeBool(isSelf, forKey: "isSelf")
        coder.encodeObject(timestamp, forKey: "timestamp")
        coder.encodeObject(peripheralID, forKey: "peripheralID")
    }

    // MARK: Hashable

    override var hashValue: Int {
        return description.hashValue ^ timestamp.hashValue
    }
}

// MARK: Equatable

func ==(lhs: BCMessage, rhs: BCMessage) -> Bool {
    return lhs.message == rhs.message && lhs.name == rhs.name && lhs.timestamp == rhs.timestamp
}

// MARK: - Public Methods

extension BCMessage {

    func isDifferentUserThan(message: BCMessage) -> Bool {
        if let peripheralID = peripheralID,
               messagePeripheralID = message.peripheralID {
            return peripheralID != messagePeripheralID
        }
        return isSelf != message.isSelf
    }

    func isSignificantlyOlderThan(message: BCMessage) -> Bool {
        let fiveMinAfter = timestamp.dateByAddingTimeInterval(60 * 3)
        return fiveMinAfter.compare(message.timestamp) == .OrderedAscending
    }
}