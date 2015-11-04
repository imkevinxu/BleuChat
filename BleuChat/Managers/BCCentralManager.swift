//
//  BCCentralManager.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CoreBluetooth
import CocoaLumberjack

// MARK: - Properties

final class BCCentralManager: NSObject {

    var centralManager: CBCentralManager!
    var discoveredPeripherals: [CBPeripheral]!
    var dataStorage: [NSUUID: NSMutableData]!

    // MARK: Delegate

    weak var delegate: BCMessageable?

    // MARK: Initializer

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        discoveredPeripherals = []
        dataStorage = [:]
    }
}

// MARK: - Public Methods

extension BCCentralManager {

    func startScanning() {
        DDLogInfo("Central started scanning")
        centralManager.scanForPeripheralsWithServices([SERVICE_CHAT_UUID], options: nil)

        // Central scans for only 10 seconds
        delay(10) {
            self.stopScanning()
        }
    }

    func stopScanning() {
        DDLogInfo("Central stopped scanning")
        centralManager.stopScan()
    }
}

// MARK: - Private Methods

extension BCCentralManager {

    private func cleanup(peripheral: CBPeripheral) {
        if peripheral.state != .Connected {
            return
        }

        DDLogDebug("Central cleaning up connections")
        if let services = peripheral.services {
            for service in services {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.UUID == CHARACTERISTIC_CHAT_UUID {
                            if characteristic.isNotifying {
                                peripheral.setNotifyValue(false, forCharacteristic: characteristic)
                            }
                        }
                    }
                }
            }
        }

        centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - Delegates

// MARK: CBCentralManagerDelegate

extension BCCentralManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
            case .PoweredOn:
                DDLogInfo("Central is powered ON")
            default:
                DDLogWarn("Central is powered OFF")
                UIApplication.presentAlert(title: "Bluetooth is Off", message: "Please turn on Bluetooth for Bleuchat to communicate with other devices")
                return
        }

        // Central is ON so start scanning
        startScanning()
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        DDLogDebug("Central discovered \"\(BCTranslator.peripheralName(peripheral))\" (State: \(BCTranslator.peripheralState(peripheral)), RSSI: \(RSSI))")

        // Store newly discovered peripheral and connect to it
        if discoveredPeripherals.indexOf(peripheral) == nil {
            discoveredPeripherals.append(peripheral)

            DDLogInfo("Central connecting to \"\(BCTranslator.peripheralName(peripheral))\"")
            centralManager.connectPeripheral(peripheral, options: nil)
        }
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        DDLogInfo("Central connected to \"\(BCTranslator.peripheralName(peripheral))\"")

        // Initialize empty data for peripheral and start looking for services
        dataStorage[peripheral.identifier] = NSMutableData()
        peripheral.delegate = self
        peripheral.discoverServices([SERVICE_CHAT_UUID])
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        DDLogInfo("Central disconnected from \"\(BCTranslator.peripheralName(peripheral))\"")

        // Remove peripheral and corresponding data from memory
        discoveredPeripherals.removeObject(peripheral)
        dataStorage.removeValueForKey(peripheral.identifier)
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let error = error {
            DDLogError("Central failed to connect to \"\(BCTranslator.peripheralName(peripheral))\". Error: \(error.localizedDescription)")
        }
        cleanup(peripheral)
    }
}

// MARK: CBPeripheralDelegate

extension BCCentralManager: CBPeripheralDelegate {

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let error = error {
            DDLogError("Central encountered error discovering services: \(error.localizedDescription)")
            cleanup(peripheral)
            return
        }

        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([CHARACTERISTIC_CHAT_UUID], forService: service)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let error = error {
            DDLogError("Central encountered error discovering characteristics: \(error.localizedDescription)")
            cleanup(peripheral)
            return
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {

                // Found desired characteristics on peripheral so subscribe to it
                if characteristic.UUID == CHARACTERISTIC_CHAT_UUID {
                    DDLogDebug("Central subscribed to \"\(BCTranslator.characteristicName(characteristic))\" on \"\(BCTranslator.peripheralName(peripheral))\"")
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            DDLogError("Central encountered error while updating notification state: \(error.localizedDescription)")
            cleanup(peripheral)
            return
        }

        if characteristic.UUID == CHARACTERISTIC_CHAT_UUID {
            if characteristic.isNotifying {
                DDLogDebug("Central will be notified by \"\(BCTranslator.characteristicName(characteristic))\" on \"\(BCTranslator.peripheralName(peripheral))\"")
            } else {
                DDLogDebug("Central stopped getting notified by \"\(BCTranslator.characteristicName(characteristic))\" on \"\(BCTranslator.peripheralName(peripheral))\". Disconnecting")
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            DDLogError("Central encountered error while retrieving updated value: \(error.localizedDescription)")
            cleanup(peripheral)
            return
        }

        if characteristic.UUID == CHARACTERISTIC_CHAT_UUID {
            guard let data = characteristic.value else {
                DDLogWarn("Central received empty data from \"\(BCTranslator.characteristicName(characteristic))\" on \"\(BCTranslator.peripheralName(peripheral))\"")
                return
            }

            if let dataString = String(data: data, encoding: NSUTF8StringEncoding),
                   dataStore = dataStorage[peripheral.identifier]
               where dataString == "EOM"
            {
                if let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(dataStore),
                    message = dataDictionary["message"],
                    name = dataDictionary["name"]
                {
                    let message = message as! String
                    let name = name as! String
                    let messageObject = BCMessage(message: message, name: name)
                    BCDefaults.appendDataObjectToArray(messageObject, forKey: .Messages)
                    if let delegate = delegate {
                        delegate.updateWithNewMessage(messageObject)
                    }
                    DDLogInfo("Central received message: \"\(message)\" from \"\(name)\"")
                }
                dataStorage[peripheral.identifier] = NSMutableData()

            } else {

                // Append data chunks to local storage
                if let dataStore = dataStorage[peripheral.identifier] {
                    dataStore.appendData(data)
                    dataStorage[peripheral.identifier] = dataStore
                } else {
                    dataStorage[peripheral.identifier] = NSMutableData(data: data)
                }
                DDLogDebug("Central received chunk \"\(data)\" from \"\(BCTranslator.characteristicName(characteristic))\" on \"\(BCTranslator.peripheralName(peripheral))\"")
            }
        }
    }
}