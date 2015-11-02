//
//  BCLogFormatter.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/2/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation
import CocoaLumberjack

final class BCLogFormatter: NSObject, DDLogFormatter {

    func formatLogMessage(logMessage: DDLogMessage!) -> String! {
        let logLevel: String
        switch logMessage.flag {
            case DDLogFlag.Error:
                logLevel = "ERROR  "
            case DDLogFlag.Warning:
                logLevel = "WARNING"
            case DDLogFlag.Info:
                logLevel = "INFO   "
            case DDLogFlag.Debug:
                logLevel = "DEBUG  "
            case DDLogFlag.Verbose:
                logLevel = "VERBOSE"
            default:
                logLevel = "DEFAULT"
                break
        }

        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let time = timeFormatter.stringFromDate(logMessage.timestamp)
        return "\(time) \(logLevel) [\(logMessage.fileName):\(logMessage.line)] \(logMessage.message)"
    }
}