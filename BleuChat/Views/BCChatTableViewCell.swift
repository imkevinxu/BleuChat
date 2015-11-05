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
    var showMetaData: Bool = true

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
                make.bottom.equalTo(messageLabel!.snp_top).offset(-2)
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

        // Create time formatter
        let timeFormatter = NSDateFormatter()
        timeFormatter.timeStyle = .ShortStyle

        // Create label and attributed string
        let metaDataLabel = UILabel(frame: CGRectZero)
        let metaDataAttributedString = NSMutableAttributedString(string: "\(message.name)  \(timeFormatter.stringFromDate(message.timestamp))")

        // Find name and time ranges
        let nameRange = (metaDataAttributedString.string as NSString).rangeOfString(message.name)
        let timeRange = (metaDataAttributedString.string as NSString).rangeOfString(timeFormatter.stringFromDate(message.timestamp))

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

        // Create and style basic label with infinite lines
        let messageLabel = UILabel()
        messageLabel.text = message.message
        messageLabel.font = UIFont.systemFontOfSize(17)
        messageLabel.lineBreakMode = .ByWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = contentView.bounds.width - 32
        return messageLabel
    }
}