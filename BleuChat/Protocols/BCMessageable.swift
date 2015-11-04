//
//  BCMessageable.swift
//  BleuChat
//
//  Created by Kevin Xu on 11/3/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import Foundation

protocol BCMessageable: class {

    func updateWithNewMessage(message: BCMessage)
}