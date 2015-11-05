//
//  BCInfoViewController.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/5/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - Properties

final class BCInfoViewController: UITableViewController {

    var peripheralManager: BCPeripheralManager!
    var chatroomUsers: [String]!

    private enum TableSectionIndex: Int {
        case Name, ChangeName, Users, Delete
    }

    // MARK: Initializers

    convenience init() {
        self.init(style: .Grouped)
    }

    override init(style: UITableViewStyle) {
        super.init(style: .Grouped)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(style: .Grouped)
    }
}

// MARK: - View Lifecycle

extension BCInfoViewController {

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if BCDevice.isPhone() {
            title = "Info"
        } else {
            title = "Information"
        }
    }
}

// MARK: - Public Methods

extension BCInfoViewController {

    func refreshUserTable(users: [String]) {
        chatroomUsers = users
        tableView.reloadData()
    }
}

// MARK: - Delegates

// MARK: UITableViewDelegate

extension BCInfoViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        view.endEditing(true)

        // User clicks on change name button
        if indexPath.section == TableSectionIndex.ChangeName.rawValue {

            // Add actions and text fields to presented alert
            let alert = UIAlertController(title: "Change Your Name", message: nil, preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler { textField in
                textField.placeholder = "Name"
                textField.autocapitalizationType = .Words
            }

            // Create save and cancel actions
            let saveNameAction = UIAlertAction(title: "Save", style: .Default) { action in
                let nameTextField = alert.textFields![0]
                if nameTextField.text != "" {
                    // Update database and other devices of name change
                    let oldName = BCDefaults.stringForKey(.Name)
                    BCDefaults.setObject(nameTextField.text, forKey: .Name)
                    self.peripheralManager.sendName(isSelf: true, oldName: oldName)

                    // Change the name currently being displayed on the info page
                    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                    let nameCell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
                    nameCell.textLabel?.text = nameTextField.text
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

            alert.addAction(saveNameAction)
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }

        // User clicks on delete history button
        if (chatroomUsers.count > 0 && indexPath.section == TableSectionIndex.Delete.rawValue) ||
           (chatroomUsers.count == 0 && indexPath.section == TableSectionIndex.Users.rawValue) {

            // Create delete and cancel actions
            let deleteHistoryAction = UIAlertAction(title: "Yes", style: .Destructive) { action in
                BCDefaults.removeObjectForKey(.Messages)

                let alert = UIAlertController(title: "History Deleted", message: "All your chat history has been successfully deleted", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            let cancelAction = UIAlertAction(title: "No", style: .Default, handler: nil)

            // Add actions to presented alert
            let alert = UIAlertController(title: "Are you sure you want to delete all your chat history?", message: "This can not be undone", preferredStyle: .Alert)
            alert.addAction(deleteHistoryAction)
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

// MARK: UITableViewDataSource

extension BCInfoViewController {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return chatroomUsers.count > 0 ? 4 : 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case TableSectionIndex.Name.rawValue:
                return 1
            case TableSectionIndex.ChangeName.rawValue:
                return 1
            case TableSectionIndex.Users.rawValue:
                return chatroomUsers.count > 0 ? chatroomUsers.count : 1
            case TableSectionIndex.Delete.rawValue:
                return 1
            default:
                return 0
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case TableSectionIndex.Name.rawValue:
                return "Your Name"
            case TableSectionIndex.Users.rawValue:
                return chatroomUsers.count > 0 ? "Chatroom Users (\(chatroomUsers.count))" : nil
            default:
                return nil
        }
    }

    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
            case TableSectionIndex.Users.rawValue:
                return chatroomUsers.count > 0 ? nil : "This will delete all your current chat history forever"
            case TableSectionIndex.Delete.rawValue:
                return "This will delete all your current chat history forever"
            default:
                return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(INFO_CELL_IDENTIFIER)
        if let cell = cell {
            cell.textLabel?.font = UIFont.systemFontOfSize(17)
            cell.textLabel?.textAlignment = .Left
            cell.textLabel?.textColor = UIColor.blackColor()
        } else {
            cell = UITableViewCell(style: .Default, reuseIdentifier: INFO_CELL_IDENTIFIER)
        }

        switch indexPath.section {
            case TableSectionIndex.Name.rawValue:
                cell!.textLabel?.text = BCDefaults.stringForKey(.Name)

            case TableSectionIndex.ChangeName.rawValue:
                cell!.textLabel?.text = "Change Name"
                cell!.textLabel?.textAlignment = .Center
                cell!.textLabel?.font = UIFont.boldSystemFontOfSize(17)
                cell!.textLabel?.textColor = UIColor(hexString: "#007AFF")

            case TableSectionIndex.Users.rawValue:
                if chatroomUsers.count > 0 {
                    cell!.textLabel?.text = chatroomUsers[indexPath.row]
                } else {
                    cell!.textLabel?.text = "Delete History"
                    cell!.textLabel?.textAlignment = .Center
                    cell!.textLabel?.font = UIFont.boldSystemFontOfSize(17)
                    cell!.textLabel?.textColor = UIColor.redColor()
                }

            case TableSectionIndex.Delete.rawValue:
                cell!.textLabel?.text = "Delete History"
                cell!.textLabel?.textAlignment = .Center
                cell!.textLabel?.font = UIFont.boldSystemFontOfSize(17)
                cell!.textLabel?.textColor = UIColor.redColor()

            default:
                break
        }
        return cell!
    }
}