//
//  BCTransportManager.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/3/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CocoaLumberjack

// MARK: - Properties

final class BCTransportManager: NSObject {


}

// MARK: - Public Methods

extension BCTransportManager {

    func sendMessage(message: String, name: String) {
        let messageObject = BCMessage(message: message, name: name, isSelf: true)
        BCDefaults.appendDataObjectToArray(messageObject, forKey: .Messages)
        DDLogInfo("Sent message: \(message)")
    }

    func receivedMessage(data: NSData) {
        if let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data),
               message = dataDictionary["message"],
               name = dataDictionary["name"] {

            let message = message as! String
            let name = name as! String
            let messageObject = BCMessage(message: message, name: name)
            BCDefaults.appendDataObjectToArray(messageObject, forKey: .Messages)
            DDLogInfo("Received message: \"\(message)\" from \"\(name)\"")
        }
    }
}