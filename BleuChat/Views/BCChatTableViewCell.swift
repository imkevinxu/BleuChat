//
//  BCChatTableViewCell.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/3/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import UIKit
import SnapKit
import SwiftColors

// MARK: - Properties

final class BCChatTableViewCell: UITableViewCell {

    var message: BCMessage?
    var messageLabel: UILabel?
    var metaDataLabel: UILabel?
    var showMetaData: Bool = false

    // Helper Variables

    var chatName: String {
        if let message = message {
            return message.name
        }
        return ""
    }
    var chatMessage: String {
        if let message = message {
            return message.message
        }
        return ""
    }

    // MARK: Initializers

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: CHAT_CELL_IDENTIFIER)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(style: .Default, reuseIdentifier: CHAT_CELL_IDENTIFIER)
    }
}

// MARK: - Custom Layout

extension BCChatTableViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()
        if let message = message {
            layoutMessage(message)
        }
    }

    private func layoutMessage(message: BCMessage) {

        // Remove old labels from dequeued cell if exists
        if let messageLabel = messageLabel {
            messageLabel.removeFromSuperview()
        }
        if let metaDataLabel = metaDataLabel {
            metaDataLabel.removeFromSuperview()
        }

        // Add and layout message label
        messageLabel = styledMessageLabel(message)
        contentView.addSubview(messageLabel!)
        messageLabel!.snp_makeConstraints { make in
            if !showMetaData {
                make.top.equalTo(contentView)
            }
            make.left.equalTo(contentView).offset(16)
            make.right.equalTo(contentView).offset(-16)
            make.bottom.equalTo(contentView).offset(-8)
        }

        // Add and layout meta data label
        if showMetaData {
            metaDataLabel = styledMetaDataLabel(message)
            contentView.addSubview(metaDataLabel!)
            metaDataLabel!.snp_makeConstraints { make in
                make.top.equalTo(contentView).offset(12)
                make.left.equalTo(contentView).offset(16)
                make.right.equalTo(contentView).offset(-16)
                if message.isStatus {
                    make.bottom.equalTo(messageLabel!.snp_top).offset(-3)
                } else {
                    make.bottom.equalTo(messageLabel!.snp_top).offset(-2)
                }
            }
        }
    }

    func layoutMessageLabelWithNewContainerWidth(width: CGFloat) {

        // Resize message label for device rotations
        messageLabel?.preferredMaxLayoutWidth = width - 32
    }
}

// MARK: - Custom Styling

extension BCChatTableViewCell {

    private func styledMetaDataLabel(message: BCMessage) -> UILabel {

        // Create date and time formatters
        // Display calendar date for date if message is older than five days
        let dateFormatter = NSDateFormatter()
        let fiveDaysAgo = NSDate().dateByAddingTimeInterval(-60 * 60 * 24 * 5)
        if fiveDaysAgo.compare(message.timestamp) == .OrderedDescending {
            dateFormatter.dateFormat = "MMM d"
        } else {
            dateFormatter.dateFormat = "EEE"
        }
        let timeFormatter = NSDateFormatter()
        timeFormatter.timeStyle = .ShortStyle

        // Create label and attributed string
        let metaDataLabel = UILabel()
        let metaDataDate = "\(dateFormatter.stringFromDate(message.timestamp)), \(timeFormatter.stringFromDate(message.timestamp))"
        let metaDataAttributedString = NSMutableAttributedString(string: "\(message.name)  \(metaDataDate)")

        // Find name and time ranges
        let nameRange = (metaDataAttributedString.string as NSString).rangeOfString(message.name)
        let timeRange = (metaDataAttributedString.string as NSString).rangeOfString(metaDataDate)

        // Create name and time attributes
        var nameAttributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(12),
            NSForegroundColorAttributeName: UIColor.blackColor()
        ]
        if message.isSelf {
            nameAttributes[NSForegroundColorAttributeName] = UIColor(hexString: "#007AFF")
        }
        let timeAttributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(12),
            NSForegroundColorAttributeName: UIColor.grayColor()
        ]

        // Add attributes to name and time at their respective ranges
        metaDataAttributedString.addAttributes(nameAttributes, range: nameRange)
        metaDataAttributedString.addAttributes(timeAttributes, range: timeRange)

        // Add attributed string to label and return label
        metaDataLabel.attributedText = metaDataAttributedString
        return metaDataLabel
    }

    private func styledMessageLabel(message: BCMessage) -> UILabel {

        let messageLabel = UILabel()
        if message.isStatus {

            // Style attributed string for statuses
            let statusMessageAttributedString = NSMutableAttributedString(string: message.message, attributes: [
                NSFontAttributeName: UIFont.italicSystemFontOfSize(15),
                NSForegroundColorAttributeName: UIColor.grayColor()
            ])
            messageLabel.attributedText = statusMessageAttributedString
        } else {

            // Style basic label with infinite lines
            messageLabel.text = message.message
            messageLabel.font = UIFont.systemFontOfSize(17)
            messageLabel.lineBreakMode = .ByWordWrapping
            messageLabel.numberOfLines = 0
            messageLabel.preferredMaxLayoutWidth = contentView.bounds.width - 32
        }
        return messageLabel
    }
}