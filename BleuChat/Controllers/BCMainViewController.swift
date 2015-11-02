//
//  BCMainViewController.swift
//  BleuChat
//
//  Created by Kevin Xu on 10/26/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit
import CoreBluetooth

import SnapKit
import CocoaLumberjack

// MARK: - Properties

final class BCMainViewController: UIViewController {

    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var data: NSData?

    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var dataToSend: NSData?
}

// MARK: - View Lifecycle

extension BCMainViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
    }

    override func viewWillDisappear(animated: Bool) {
        centralManager.stopScan()
        DDLogInfo("Central stopped scanning")
        peripheralManager.stopAdvertising()
        DDLogInfo("Peripheral stopped advertising")

        super.viewWillDisappear(animated)
    }

    // MARK: Setup Methods

    private func setupViewController() {
        view.backgroundColor = UIColor.whiteColor()

        let centralButton = UIButton(type: .System)
        centralButton.setTitle("Central", forState: .Normal)
        centralButton.addTarget(self, action: "centralButtonTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(centralButton)
        centralButton.snp_makeConstraints { make in
            make.center.equalTo(view).offset(CGPointMake(0, -100))
        }

        let peripheralButton = UIButton(type: .System)
        peripheralButton.setTitle("Peripheral", forState: .Normal)
        peripheralButton.addTarget(self, action: "peripheralButtonTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(peripheralButton)
        peripheralButton.snp_makeConstraints { make in
            make.center.equalTo(view)
        }

        let sendButton = UIButton(type: .System)
        sendButton.setTitle("Send Message", forState: .Normal)
        sendButton.addTarget(self, action: "sendButtonTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(sendButton)
        sendButton.snp_makeConstraints { make in
            make.center.equalTo(view).offset(CGPointMake(0, 100))
        }

        let scanButton = UIButton(type: .System)
        scanButton.setTitle("Scan", forState: .Normal)
        scanButton.addTarget(self, action: "scanButtonTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(scanButton)
        scanButton.snp_makeConstraints { make in
            make.center.equalTo(view).offset(CGPointMake(0, 200))
        }
    }
}


// MARK: - User Interaction

extension BCMainViewController {

    func centralButtonTapped(sender: UIButton) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func peripheralButtonTapped(sender: UIButton) {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func sendButtonTapped(sender: UIButton) {
        sendData()
    }

    func scanButtonTapped(sender: UIButton) {
        centralManager.scanForPeripheralsWithServices([SERVICE_CHAT_UUID], options: nil)
        DDLogInfo("Central started scanning")

        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: "\(UIDevice.currentDevice().name) - \(NSDate().timeIntervalSince1970 * 1000)",
            CBAdvertisementDataServiceUUIDsKey: [SERVICE_CHAT_UUID]
            ])
        DDLogInfo("Peripheral started advertising as \(UIDevice.currentDevice().name) - \(NSDate().timeIntervalSince1970 * 1000)")
    }
}

// MARK: - Delegates

// MARK: CBCentralManagerDelegate

extension BCMainViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOn:
            DDLogInfo("Central is powered on")
        default:
            DDLogInfo("Central is not powered on")
            return
        }
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {

        DDLogInfo("Discovered \(peripheral.name) at \(RSSI)")
        if peripheral != discoveredPeripheral {
            discoveredPeripheral = peripheral
            centralManager.connectPeripheral(peripheral, options: nil)
        }
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        DDLogInfo("Failed to connect to \(peripheral.name). \(error?.localizedDescription)")
        cleanup()
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        DDLogInfo("Connected to \(peripheral.name)")
        //        centralManager.stopScan()
        //        DDLogInfo("Central stopped scanning")

        data = NSData()
        peripheral.delegate = self
        peripheral.discoverServices([SERVICE_CHAT_UUID])
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        DDLogInfo("\(peripheral.name) disconnected")
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

extension BCMainViewController: CBPeripheralDelegate {
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error != nil {
            DDLogInfo("Error discovering services: \(error?.localizedDescription)")
            cleanup()
            return
        }

        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CHARACTERISTIC_CHAT_UUID], forService: service)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error != nil {
            DDLogInfo("Error discovering characteristics: \(error?.localizedDescription)")
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
            DDLogInfo("Error discovering characteristics: \(error?.localizedDescription)")
            cleanup()
            return
        }

        let stringFromData = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        DDLogInfo("Received: \(stringFromData)")

        let label = UILabel()
        label.text = stringFromData as? String
        view.addSubview(label)
        label.snp_makeConstraints { make in
            make.center.equalTo(view).offset(CGPointMake(0, -200))
        }
    }
}





// MARK: CBPeripheralManagerDelegate

extension BCMainViewController: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            DDLogInfo("Peripheral is powered on")
        default:
            DDLogInfo("Peripheral is not powered on")
            return
        }

        transferCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_CHAT_UUID, properties: .Notify, value: nil, permissions: .Readable)
        let transferService = CBMutableService(type: SERVICE_CHAT_UUID, primary: true)

        guard let transferCharacteristic = transferCharacteristic else { return }
        transferService.characteristics = [transferCharacteristic]
        peripheralManager.addService(transferService)
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        DDLogInfo("Central subscribed to characteristic")
        //        peripheralManager.stopAdvertising()
        //        DDLogInfo("Peripheral stopped advertising")
    }

    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        DDLogInfo("Central unsubscribed to characteristic")
    }

    private func sendData() {
        dataToSend = "HELLO WORLD!".dataUsingEncoding(NSUTF8StringEncoding)

        let didSend = peripheralManager.updateValue(dataToSend!, forCharacteristic: transferCharacteristic!, onSubscribedCentrals: nil)
        if !didSend {
            return
        }
        
        let stringFromData = NSString(data: dataToSend!, encoding: NSUTF8StringEncoding)
        DDLogInfo("Sent: \(stringFromData)")
    }
}