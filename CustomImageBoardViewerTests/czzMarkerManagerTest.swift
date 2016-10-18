//
//  czzMarkerManagerTest.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

import XCTest

class czzMarkerManagerTest: XCTestCase {
    let UID1 = "0123456789"
    let UID2 = "abcdEfGh"
        
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        czzMarkerManager.sharedInstance().reset();
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMarkerManagerSaveBlockedUIDs() {
        czzMarkerManager.sharedInstance().blockUID(UID1)
        czzMarkerManager.sharedInstance().blockUID(UID2)
        // A new instance of czzMarkerManager.
        let newMarkerManager = czzMarkerManager()
        XCTAssert(newMarkerManager.isUIDBlocked(UID1))
        XCTAssert(newMarkerManager.isUIDBlocked(UID2))
    }
    
    func testMarkerManagerSaveHighlightedUIDs() {
        czzMarkerManager.sharedInstance().highlightUID(UID1)
        czzMarkerManager.sharedInstance().highlightUID(UID2)
        // A new instance of czzMarkerManager.
        let newMarkerManager = czzMarkerManager()
        XCTAssert(newMarkerManager.isUIDHighlighted(UID1))
        XCTAssert(newMarkerManager.isUIDHighlighted(UID2))
    }
}
