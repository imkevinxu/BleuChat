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
    var discoveredPeripheral: CBPeripheral?
    var discoveredPeripherals: [CBPeripheral?]
    let data = NSMutableData()

    // MARK: Initializer

    override init() {
        discoveredPeripherals = []
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}




// MARK: - Delegates

// MARK: CBCentralManagerDelegate

extension BCCentralManager: CBCentralManagerDelegate {


    func scan() {

        centralManager.scanForPeripheralsWithServices([SERVICE_CHAT_UUID], options: nil)
        DDLogDebug("Central started scanning")
    }

    func stop() {

                centralManager.stopScan()
                DDLogDebug("Central stopped scanning")
    }


    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
            case .PoweredOn:
                DDLogDebug("Central is powered on")
            default:
                DDLogDebug("Central is not powered on")
                return
        }
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {

        DDLogDebug("Discovered \(peripheral.name) at \(RSSI)")
        if peripheral != discoveredPeripheral {
            discoveredPeripheral = peripheral
            centralManager.connectPeripheral(peripheral, options: nil)
        }
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        DDLogDebug("Failed to connect to \(peripheral.name). \(error?.localizedDescription)")
        cleanup()
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        DDLogDebug("Connected to \(peripheral.name)")
        //        centralManager.stopScan()
        //        DDLogDebug("Central stopped scanning")

        // data associated to peripheral ID
        data.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([SERVICE_CHAT_UUID])
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        DDLogDebug("\(peripheral.name) disconnected")
        discoveredPeripheral = nil
    }






    private func cleanup() {
        guard let discoveredPeripheral = discoveredPeripheral
            else { return }

        if discoveredPeripheral.state != .Connected {
            return
        }

        if discoveredPeripheral.services != nil {
            for service in discoveredPeripheral.services! {
                if service.characteristics != nil {
                    for characteristic in service.characteristics! {
                        if characteristic.UUID == CHARACTERISTIC_CHAT_UUID {
                            if characteristic.isNotifying {
                                discoveredPeripheral.setNotifyValue(false, forCharacteristic: characteristic)
                                return
                            }
                        }
                    }
                }
            }
        }

        centralManager.cancelPeripheralConnection(discoveredPeripheral)
    }
}



// MARK: CBPeripheralDelegate

extension BCCentralManager: CBPeripheralDelegate {
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error != nil {
            DDLogDebug("Error discovering services: \(error?.localizedDescription)")
            cleanup()
            return
        }

        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CHARACTERISTIC_CHAT_UUID], forService: service)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error != nil {
            DDLogDebug("Error discovering characteristics: \(error?.localizedDescription)")
            cleanup()
            return
        }

        for characteristic in service.characteristics! {
            if characteristic.UUID == CHARACTERISTIC_CHAT_UUID {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            DDLogDebug("Error getting updated value: \(error?.localizedDescription)")
            return
        }

        let stringFromData = String(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        data.appendData(characteristic.value!)
        // or remove data stuff
        DDLogDebug("Received: \(stringFromData)")

    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {

        if error != nil {
            DDLogDebug("Error changing notification state: \(error?.localizedDescription)")
            return
        }

        if characteristic.UUID != CHARACTERISTIC_CHAT_UUID {
            return
        }
        if characteristic.isNotifying {
            DDLogDebug("Notification began on: \(characteristic)")
        } else {
            DDLogDebug("Notification stopped on: \(characteristic). Disconnecting")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}