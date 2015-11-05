//
//  BCConstants.swift
//  BleuChat
//
//  Created by Kevin Xu on 10/26/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CoreBluetooth

// Bluetooth Constants

let BLUETOOTH_DATA_LENGTH = 20
let SERVICE_CHAT_UUID = CBUUID(string: "FA1A37A9-12D4-46C7-9D01-91CB14D17708")
let CHARACTERISTIC_MESSAGE_UUID = CBUUID(string: "9ED1EF05-FFC0-4CD3-8096-5AB5A3F6B805")
let CHARACTERISTIC_NAME_UUID = CBUUID(string: "988ACA9E-CAC3-4315-A5FF-63D226D217FF")

// Chatroom Constants

let CHAT_CELL_IDENTIFIER = "CHAT_CELL_IDENTIFIER"