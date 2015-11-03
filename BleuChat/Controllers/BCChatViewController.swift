//
//  BCChatViewController.swift
//  BleuChat
//
//  Created by Kevin Xu on 10/26/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit
import CoreBluetooth
import CocoaLumberjack
import SnapKit

// MARK: - Properties

final class BCChatViewController: UIViewController {

    var centralManager: BCCentralManager!
    var peripheralManager: BCPeripheralManager!
}

// MARK: - View Lifecycle

extension BCChatViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
    }

    override func viewWillDisappear(animated: Bool) {
        centralManager.stop()
        peripheralManager.stop()

        super.viewWillDisappear(animated)
    }

    // MARK: Setup Methods

    private func setupViewController() {
        title = "Chat"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "scanButtonTapped:")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info"), style: .Plain, target: self, action: nil)

        let sendButton = UIButton(type: .System)
        sendButton.setTitle("Send Message", forState: .Normal)
        sendButton.addTarget(self, action: "sendButtonTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(sendButton)
        sendButton.snp_makeConstraints { make in
            make.center.equalTo(view)
        }
    }
}


// MARK: - User Interaction

extension BCChatViewController {

    func sendButtonTapped(sender: UIButton) {
        peripheralManager.sendData()
    }

    func scanButtonTapped(sender: UIButton) {
        centralManager.scan()
        peripheralManager.advertise()
    }
}
