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
    var messageCharacteristic: CBMutableCharacteristic!
    var nameCharacteristic: CBMutableCharacteristic!
    var sendingData: NSData = NSData()
    var sendingDataIndex: Int = 0
    var sendingCharacteristic: CBMutableCharacteristic!
    var sendingEOM: Bool = false
    var timer: NSTimer?

    // MARK: Delegate

    weak var delegate: BCChatRoomProtocol?

    // MARK: Initializer

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        messageCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_MESSAGE_UUID, properties: .Notify, value: nil, permissions: .Readable)
        nameCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_NAME_UUID, properties: .Notify, value: nil, permissions: .Readable)
    }
}

// MARK: - Public Methods

extension BCPeripheralManager {

    func startAdvertising(s: Double) {
        let deviceName = "\(UIDevice.currentDevice().name) - \(Int(NSDate().timeIntervalSinceReferenceDate * 1000000))"

        DDLogInfo("Peripheral started advertising for \(s) seconds")
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: deviceName,
            CBAdvertisementDataServiceUUIDsKey: [SERVICE_CHAT_UUID]
        ])

        // Peripheral advertises for only 10 seconds
        delay(s) {
            self.stopAdvertising()
        }
    }

    func startAdvertisingFromTimer(timer: NSTimer) {
        if timer.userInfo is Double {
            startAdvertising(timer.userInfo as! Double)
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

        let messageObject = BCMessage(message: message, name: name, isSelf: true)
        BCDefaults.appendDataObjectToArray(messageObject, forKey: .Messages)
        delegate?.updateWithNewMessage(messageObject)
        DDLogInfo("Peripheral sending message: \"\(message)\"")

        sendingData = NSKeyedArchiver.archivedDataWithRootObject([
            "message": message,
            "name": name
        ])
        sendingCharacteristic = messageCharacteristic
        sendData()
    }

    func sendName(isSelf isSelf: Bool = false, oldName: String? = nil) {
        guard let name = BCDefaults.stringForKey(.Name) else {
            UIApplication.presentAlert(title: "Name Not Set", message: "Please enter your name by clicking the information icon in the top right corner")
            return
        }

        if let oldName = oldName where isSelf {
            let message = BCMessage(message: "Changed their name to \(name)", name: oldName, isSelf: true, isStatus: true)
            BCDefaults.appendDataObjectToArray(message, forKey: .Messages)
            delegate?.updateWithNewMessage(message)
        }

        DDLogInfo("Peripheral sending name: \"\(name)\"")
        sendingData = name.dataUsingEncoding(NSUTF8StringEncoding)!
        sendingCharacteristic = nameCharacteristic
        sendData()
    }
}

// MARK: - Private Methods

extension BCPeripheralManager {

    private func sendData() {
        guard let eomData = "EOM".dataUsingEncoding(NSUTF8StringEncoding) else { return }
        var didSend = true

        if sendingEOM {
            didSend = peripheralManager.updateValue(eomData, forCharacteristic: sendingCharacteristic, onSubscribedCentrals: nil)
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
            didSend = peripheralManager.updateValue(chunk, forCharacteristic: sendingCharacteristic, onSubscribedCentrals: nil)
            if !didSend {
                return
            }
            DDLogDebug("Peripheral sent data: \"\(chunk)\"")

            sendingDataIndex += amountToSend
            if sendingDataIndex >= sendingData.length {
                sendingEOM = true
                sendingDataIndex = 0
                didSend = peripheralManager.updateValue(eomData, forCharacteristic: sendingCharacteristic, onSubscribedCentrals: nil)
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
                peripheralManager.removeAllServices()
                let transferService = CBMutableService(type: SERVICE_CHAT_UUID, primary: true)
                transferService.characteristics = [messageCharacteristic, nameCharacteristic]
                peripheralManager.addService(transferService)
            default:
                DDLogWarn("Peripheral is powered OFF")
                if let timer = timer {
                    timer.invalidate()
                }
                UIApplication.presentAlert(title: "Bluetooth is Off", message: "Please turn on Bluetooth for Bleuchat to communicate with other devices")
                return
        }

        // Peripheral is ON so start advertising for 10 seconds
        startAdvertising(10)

        // Repeat advertising every minute for 3 seconds
        timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "startAdvertisingFromTimer:", userInfo: 3, repeats: true)
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
        if characteristic.UUID == CHARACTERISTIC_NAME_UUID {
            sendName()
        }
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        DDLogDebug("Peripheral's \"\(BCTranslator.characteristicName(characteristic))\" has been unsubscribed to by a central")
    }

    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        DDLogDebug("Peripheral is ready to send data")
        sendData()
    }
}