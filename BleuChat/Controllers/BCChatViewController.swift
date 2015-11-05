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
import SlackTextViewController
import AudioToolbox

// MARK: - Properties

final class BCChatViewController: SLKTextViewController {

    let infoViewController = BCInfoViewController()

    var centralManager: BCCentralManager!
    var peripheralManager: BCPeripheralManager!
    var cachedMessages: [BCMessage]!
    var cachedHeights: [Int: CGFloat] = [:]
    var chatroomUsers: [NSUUID: String] = [:]

    // MARK: Initializers

    init() {
        super.init(tableViewStyle: .Plain)
    }

    required convenience init!(coder decoder: NSCoder!) {
        self.init()
    }
}

// MARK: - View Lifecycle

extension BCChatViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        setupViewController()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Reload chatroom if messages have been changed in the database
        let storedMessages = BCDefaults.dataObjectArrayForKey(.Messages)?.reverse() as [BCMessage]!
        if storedMessages == nil || storedMessages.count != cachedMessages.count {
            cachedMessages = storedMessages == nil ? [] : storedMessages
            tableView.reloadData()
        }
    }

    override func viewWillDisappear(animated: Bool) {

        // Stop scanning if view controller disappears
        centralManager.stopScanning()
        peripheralManager.stopAdvertising()

        // Make sure keyboard is not showing when we rewind back
        view.endEditing(true)

        super.viewWillDisappear(animated)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        // Reset cachedHeights on orientation change
        cachedHeights = [:]
    }

    // MARK: Setup Methods

    private func configureViewController() {

        // Set delegates
        centralManager.delegate = self
        peripheralManager.delegate = self

        // Configure text input
        shakeToClearEnabled = true

        // Retrieve cached messages from local database
        if let storedMessages = BCDefaults.dataObjectArrayForKey(.Messages)?.reverse() as [BCMessage]! {
            cachedMessages = storedMessages
        } else {
            cachedMessages = []
        }

        // Register custom table view cell class for reuse
        tableView.registerClass(BCChatTableViewCell.self, forCellReuseIdentifier: CHAT_CELL_IDENTIFIER)
    }

    private func setupViewController() {
        title = "Chatroom (\(chatroomUsers.count + 1))"

        // Set navigation bar items
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "scanButtonTapped:")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info"), style: .Plain, target: self, action: "infoButtonTapped:")

        // Setup table view
        tableView.separatorStyle = .None
        tableView.allowsSelection = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = tableView.rowHeight

        // Change text view placeholder
        textView.placeholder = "Type a message…"

        setupName()
    }

    private func setupName() {

        // Ask for name if user is opened app for the first time
        if BCDefaults.stringForKey(.Name) == nil {
            let alert = UIAlertController(title: "Welcome", message: "Please set your name, it can be anything you want!", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler { textField in
                textField.placeholder = "Name"
                textField.autocapitalizationType = .Words
            }

            // Create save and cancel actions
            let saveNameAction = UIAlertAction(title: "Save", style: .Default) { action in
                let nameTextField = alert.textFields![0]
                if nameTextField.text != "" {
                    BCDefaults.setObject(nameTextField.text, forKey: .Name)
                } else {
                    self.setupName()
                }
            }

            alert.addAction(saveNameAction)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
}


// MARK: - User Interaction

extension BCChatViewController {

    func scanButtonTapped(sender: UIButton) {

        // Start looking for connections for 10 seconds
        centralManager.startScanning(10)
        peripheralManager.startAdvertising(10)
    }

    func infoButtonTapped(sender: UIButton) {

        // Segue to info view controller
        if let navigationController = navigationController {
            infoViewController.peripheralManager = peripheralManager
            infoViewController.chatroomUsers = Array(chatroomUsers.values)
            navigationController.pushViewController(infoViewController, animated: true)
        }
    }

    override func didPressRightButton(sender: AnyObject!) {

        // Finish any auto-correction
        textView.refreshFirstResponder()

        // Send trimmed message and reset text view
        peripheralManager.sendMessage(self.textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        textView.text = ""

        super.didPressRightButton(sender)
    }
}

// MARK: - Delegates

// MARK: BCChatRoomProtocol

extension BCChatViewController: BCChatRoomProtocol {

    func didStartScanning() {
        title = "Scanning…"

        // Replace scan button with activity indicator
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    }

    func didFinishScanning() {
        title = "Chatroom (\(chatroomUsers.count + 1))"

        // Add the scan button back
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "scanButtonTapped:")
    }

    func updateWithNewMessage(message: BCMessage) {

        // Cache new message locally
        cachedMessages.insert(message, atIndex: 0)

        // Asynchronously update the table view with the new message
        dispatch_async(dispatch_get_main_queue(), {
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
            self.tableView.endUpdates()

            // Vibrate phone when receiving new message
            if !message.isSelf {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }

            // Scroll to most recent message if user sent it
            if message.isSelf {
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
            }
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        })
    }

    func userJoined(name: String, peripheralID: NSUUID) {
        if let oldName = chatroomUsers[peripheralID] {
            if oldName != name {
                // Update user's name in local cache
                chatroomUsers[peripheralID] = name

                // Update info view controller
                infoViewController.refreshUserTable(Array(chatroomUsers.values))

                // Create and add status message to local database
                let message = BCMessage(message: "> Changed their name to \(name)", name: oldName, isStatus: true, peripheralID: peripheralID)
                BCDefaults.appendDataObjectToArray(message, forKey: .Messages)

                // Send status message
                updateWithNewMessage(message)

                if !message.isSelf {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
            }

        } else {

            // Add user to local cache
            chatroomUsers[peripheralID] = name

            // Update info view controller
            infoViewController.refreshUserTable(Array(chatroomUsers.values))

            // Create and add status message to local database
            let message = BCMessage(message: "> Joined the room", name: name, isStatus: true, peripheralID: peripheralID)
            BCDefaults.appendDataObjectToArray(message, forKey: .Messages)

            // Send status message
            updateWithNewMessage(message)

            if !message.isSelf {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }

        title = "Chatroom (\(chatroomUsers.count + 1))"
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func userLeft(peripheralID: NSUUID) {
        if let name = chatroomUsers[peripheralID] {

            // Remove user from local cache
            chatroomUsers.removeValueForKey(peripheralID)

            // Update info view controller
            infoViewController.refreshUserTable(Array(chatroomUsers.values))

            // Create and add status message to local database
            let message = BCMessage(message: "> Left the room", name: name, isStatus: true, peripheralID: peripheralID)
            BCDefaults.appendDataObjectToArray(message, forKey: .Messages)

            // Send status message
            updateWithNewMessage(message)
        }
        title = "Chatroom (\(chatroomUsers.count + 1))"
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
}

// MARK: UITableViewDelegate

extension BCChatViewController {

    override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return action == "copy:"
    }

    override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if action == "copy:" {
            let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath) as! BCChatTableViewCell
            UIPasteboard.generalPasteboard().string = cell.chatMessage
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < cachedMessages.count {
            let message = cachedMessages[indexPath.row]

            // Return cached height if it's been stored
            if cachedHeights[message.hashValue] != nil {
                return cachedHeights[message.hashValue]!
            } else {

                // Set the message and meta data for the cell
                let cell = BCChatTableViewCell(style: .Default, reuseIdentifier: CHAT_CELL_IDENTIFIER)
                cell.message = message
                cell.showMetaData = isDifferentThanPreviousMessage(cachedMessages, indexPath: indexPath)

                // Relayout the cell's subviews
                cell.layoutIfNeeded()

                // Resizes labels for rotation
                cell.layoutMessageLabelWithNewContainerWidth(tableView.bounds.width)

                // Cache the height of the cell to reduce future calculations
                cachedHeights[message.hashValue] = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
                return cachedHeights[message.hashValue]!
            }
        }
        return tableView.rowHeight
    }
}

// MARK: UITableViewDataSource

extension BCChatViewController {

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cachedMessages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Initialize or dequeue a cell
        let cell = tableView.dequeueReusableCellWithIdentifier(CHAT_CELL_IDENTIFIER, forIndexPath: indexPath) as! BCChatTableViewCell
        cell.transform = tableView.transform
        cell.selectionStyle = .None

        // Set the message and meta data for the cell
        if indexPath.row < cachedMessages.count {
            let message = cachedMessages[indexPath.row]
            cell.message = message
            cell.showMetaData = isDifferentThanPreviousMessage(cachedMessages, indexPath: indexPath)
        }
        return cell
    }
}

// MARK: UIGestureRecognizerDelegate

extension BCChatViewController {

    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        // Don't hide keyboard on tapping table view
        if textView.isFirstResponder() && gestureRecognizer == singleTapGesture {
            return false
        }
        return true
    }
}

// MARK: - Helper Methods

extension BCChatViewController {

    // Helper function to determine if current messsage should show meta data or not
    // Returns true if previous message is either a different user or older than 5 minutes
    func isDifferentThanPreviousMessage(messages: [BCMessage], indexPath: NSIndexPath) -> Bool {
        if indexPath.row == messages.count - 1 {
            return true

        } else if indexPath.row < messages.count - 1 {
            let currentMessage = messages[indexPath.row]
            let previousMessage = messages[indexPath.row + 1]
            if currentMessage.isDifferentUserThan(previousMessage) || currentMessage.isSignificantlyOlderThan(previousMessage) {
                return true
            }
        }
        return false
    }
}