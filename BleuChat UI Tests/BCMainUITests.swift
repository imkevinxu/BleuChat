//
//  BCMainUITests.swift
//  BleuChat UI Tests
//
//  Created by Kevin Xu on 10/26/15.
//  Copyright © 2015 Kevin Xu. All rights reserved.
//

import XCTest

class BCMainUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        XCTAssertTrue(true)
    }
}
