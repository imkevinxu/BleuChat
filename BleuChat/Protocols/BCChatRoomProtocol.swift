//
//  BCChatRoomProtocol.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/3/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation

protocol BCChatRoomProtocol: class {

    func didStartScanning()
    func didFinishScanning()

    func updateWithNewMessage(message: BCMessage)
}