//
//  BCInfoViewController.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/5/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit

// MARK: - Properties

final class BCInfoViewController: UITableViewController {

    var peripheralManager: BCPeripheralManager!
    var chatroomUsers: [String]!

    private enum TableSectionIndex: Int {
        case Name, Users, Delete
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

// MARK: UITableViewDataSource

extension BCInfoViewController {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return chatroomUsers.count > 0 ? 3 : 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case TableSectionIndex.Name.rawValue:
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