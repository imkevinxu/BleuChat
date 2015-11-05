//
//  BCTranslator.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Methods

struct BCTranslator {

    // MARK: Peripherals

    static func peripheralName(peripheral: CBPeripheral) -> String {
        if let peripheralName = peripheral.name {
            return peripheralName
        } else {
            return "Peripheral ID \(peripheral.identifier.UUIDString)"
        }
    }

    static func peripheralState(peripheral: CBPeripheral) -> String {
        switch peripheral.state {
            case .Connected:
                return "Connected"
            case .Connecting:
                return "Connecting"
            case .Disconnecting:
                return "Disconnecting"
            case .Disconnected:
                return "Disconnected"
        }
    }

    // MARK: Characteristics

    static func characteristicName(characteristic: CBCharacteristic) -> String {
        if characteristic.UUID == CHARACTERISTIC_MESSAGE_UUID {
            return "Message Characteristic"
        } else if characteristic.UUID == CHARACTERISTIC_NAME_UUID {
            return "Name Characteristic"
        } else {
            return "Characteristic ID \(characteristic.UUID.UUIDString)"
        }
    }
}