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
    var transferCharacteristic: CBMutableCharacteristic!
    var sendingData: NSData = NSData()
    var sendingDataIndex: Int = 0
    var sendingEOM: Bool = false

    // MARK: Delegate

    weak var delegate: BCMessageable?

    // MARK: Initializer

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        transferCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_CHAT_UUID, properties: .Notify, value: nil, permissions: .Readable)
    }
}

// MARK: - Public Methods

extension BCPeripheralManager {

    func startAdvertising() {
        let deviceName = "\(UIDevice.currentDevice().name) - \(Int(NSDate().timeIntervalSinceReferenceDate * 1000000))"

        DDLogInfo("Peripheral started advertising as \"\(deviceName)\"")
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: deviceName,
            CBAdvertisementDataServiceUUIDsKey: [SERVICE_CHAT_UUID]
        ])

        // Peripheral advertises for only 10 seconds
        delay(10) {
            self.stopAdvertising()
        }
    }

    func stopAdvertising() {
        DDLogInfo("Peripheral stopped advertising")
        peripheralManager.stopAdvertising()
    }

    func sendMessage(message: String) {
        guard let name = BCDefaults.stringForKey(.Name) else {
            UIApplication.presentAlert(title: "Name Not Set", message: "Please enter your name by clicking the information icon in the top right corner")
            return
        }
        sendingData = NSKeyedArchiver.archivedDataWithRootObject([
            "message": message,
            "name": name
        ])

        let messageObject = BCMessage(message: message, name: name, isSelf: true)
        BCDefaults.appendDataObjectToArray(messageObject, forKey: .Messages)
        if let delegate = delegate {
            delegate.updateWithNewMessage(messageObject)
        }
        DDLogInfo("Peripheral sending message: \"\(message)\"")
        sendData()
    }
}

// MARK: - Private Methods

extension BCPeripheralManager {

    private func sendData() {
        guard let eomData = "EOM".dataUsingEncoding(NSUTF8StringEncoding) else { return }
        var didSend = true

        if sendingEOM {
            didSend = peripheralManager.updateValue(eomData, forCharacteristic: transferCharacteristic, onSubscribedCentrals: nil)
            if didSend {
                sendingEOM = false
                DDLogDebug("Peripheral sent: <EOM>")
            }
            return
        }

        if sendingDataIndex >= sendingData.length {
            sendingDataIndex = 0
            return
        }

        while didSend {
            var amountToSend = sendingData.length - sendingDataIndex
            if amountToSend > BLUETOOTH_DATA_LENGTH {
                amountToSend = BLUETOOTH_DATA_LENGTH
            }

            let chunk = NSData(bytes: sendingData.bytes + sendingDataIndex, length: amountToSend)
            didSend = peripheralManager.updateValue(chunk, forCharacteristic: transferCharacteristic, onSubscribedCentrals: nil)
            if !didSend {
                return
            }
            DDLogDebug("Peripheral sent data: \"\(chunk)\"")

            sendingDataIndex += amountToSend
            if sendingDataIndex >= sendingData.length {
                sendingEOM = true
                sendingDataIndex = 0
                didSend = peripheralManager.updateValue(eomData, forCharacteristic: transferCharacteristic, onSubscribedCentrals: nil)
                if didSend {
                    sendingEOM = false
                    DDLogDebug("Peripheral sent: <EOM>")
                }
                return
            }
        }
    }
}

// MARK: - Delegates

// MARK: CBPeripheralManagerDelegate

extension BCPeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
            case .PoweredOn:
                DDLogDebug("Peripheral is powered ON")
                let transferService = CBMutableService(type: SERVICE_CHAT_UUID, primary: true)
                transferService.characteristics = [transferCharacteristic]
                peripheralManager.addService(transferService)
            default:
                DDLogWarn("Peripheral is powered OFF")
                UIApplication.presentAlert(title: "Bluetooth is Off", message: "Please turn on Bluetooth for Bleuchat to communicate with other devices")
                return
        }

        // Peripheral is ON so start advertising
        startAdvertising()
    }

    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if let error = error {
            DDLogError("Peripheral encountered error adding services: \(error.localizedDescription)")
        }
    }

    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if let error = error {
            DDLogError("Peripheral encountered error advertising: \(error.localizedDescription)")
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        DDLogDebug("Peripheral's \"\(BCTranslator.characteristicName(characteristic))\" has been subscribed to by a central")
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        DDLogDebug("Peripheral's \"\(BCTranslator.characteristicName(characteristic))\" has been unsubscribed to by a central")
    }

    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        DDLogDebug("Peripheral is ready to send data")
        sendData()
    }
}