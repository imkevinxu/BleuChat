//
//  BCPeripheralManager.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CoreBluetooth
import CocoaLumberjack

// MARK: - Properties

final class BCPeripheralManager: NSObject {

    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?

    // MARK: Initializer

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func advertise() {


        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "\(UIDevice.currentDevice().name) - \(NSDate().timeIntervalSince1970 * 1000)",
            CBAdvertisementDataServiceUUIDsKey: [SERVICE_CHAT_UUID]
            ])
        DDLogDebug("Peripheral started advertising as \(UIDevice.currentDevice().name) - \(NSDate().timeIntervalSince1970 * 1000)")
    }

    func stop() {

                peripheralManager.stopAdvertising()
                DDLogDebug("Peripheral stopped advertising")
    }
}

// MARK: - Delegates

// MARK: CBPeripheralManagerDelegate

extension BCPeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            DDLogDebug("Peripheral is powered on")
        default:
            DDLogDebug("Peripheral is not powered on")
            return
        }

        transferCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_CHAT_UUID, properties: .Notify, value: nil, permissions: .Readable)
        let transferService = CBMutableService(type: SERVICE_CHAT_UUID, primary: true)

        guard let transferCharacteristic = transferCharacteristic else { return }
        transferService.characteristics = [transferCharacteristic]
        peripheralManager.addService(transferService)
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        DDLogDebug("Central subscribed to characteristic")
        //        peripheralManager.stopAdvertising()
        //        DDLogDebug("Peripheral stopped advertising")
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        DDLogDebug("Central unsubscribed to characteristic")
    }

    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        DDLogDebug("Sending next chunk")
        sendData()
    }

    func sendData() {
        let dataToSend = "HELLO WORLD!".dataUsingEncoding(NSUTF8StringEncoding)

        let didSend = peripheralManager.updateValue(dataToSend!, forCharacteristic: transferCharacteristic!, onSubscribedCentrals: nil)
        if !didSend {
            return
        }

        let stringFromData = String(data: dataToSend!, encoding: NSUTF8StringEncoding)
        DDLogDebug("Sent: \(stringFromData)")
    }
}