//
//  BCMessage.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation

// MARK: - Properties

final class BCMessage: NSObject, NSCoding {

    var message: String
    var name: String
    var isSelf: Bool
    var timestamp: NSDate

    // MARK: Description

    override var description: String {
        return "\(name): \(message)"
    }

    // MARK: Initializers

    init(message: String, name: String, isSelf: Bool = false, timestamp: NSDate = NSDate()) {
        self.message = message
        self.name = name
        self.isSelf = isSelf
        self.timestamp = timestamp
    }

    // MARK: - NSCoding

    required convenience init?(coder decoder: NSCoder) {
        guard let message = decoder.decodeObjectForKey("message") as? String,
                  name = decoder.decodeObjectForKey("name") as? String,
                  timestamp = decoder.decodeObjectForKey("timestamp") as? NSDate
            else { return nil }

        self.init(
            message: message,
            name: name,
            isSelf: decoder.decodeBoolForKey("isSelf"),
            timestamp: timestamp
        )
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(message, forKey: "message")
        coder.encodeObject(name, forKey: "name")
        coder.encodeBool(isSelf, forKey: "isSelf")
        coder.encodeObject(timestamp, forKey: "timestamp")
    }
}