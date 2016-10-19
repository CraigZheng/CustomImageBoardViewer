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
        czzMarkerManager.sharedInstance().highlightUID(UID1, withColour: UIColor.blue)
        czzMarkerManager.sharedInstance().highlightUID(UID2, withColour: UIColor.yellow)
        // A new instance of czzMarkerManager.
        let newMarkerManager = czzMarkerManager()
        XCTAssert(newMarkerManager.highlightColour(forUID: UID1) == UIColor.blue)
        XCTAssert(newMarkerManager.highlightColour(forUID: UID2) == UIColor.yellow)
    }
    
    func testMarkerReset() {
        czzMarkerManager.sharedInstance().highlightUID(UID1, withColour: UIColor.blue)
        czzMarkerManager.sharedInstance().highlightUID(UID2, withColour: UIColor.yellow)
        czzMarkerManager.sharedInstance().blockUID(UID1)
        czzMarkerManager.sharedInstance().blockUID(UID2)
        czzMarkerManager.sharedInstance().reset()
        // New marker should not contain any entity.
        let newMarkerManager = czzMarkerManager()
        XCTAssert(newMarkerManager.highlightColour(forUID: UID1) == nil)
        XCTAssert(newMarkerManager.highlightColour(forUID: UID2) == nil)
        XCTAssertFalse(newMarkerManager.isUIDBlocked(UID1))
        XCTAssertFalse(newMarkerManager.isUIDBlocked(UID2))
    }
    
    func testMarkerRemove() {
        czzMarkerManager.sharedInstance().highlightUID(UID1, withColour: UIColor.blue)
        czzMarkerManager.sharedInstance().highlightUID(UID2, withColour: UIColor.yellow)
        czzMarkerManager.sharedInstance().unHighlightUID(UID1)
        czzMarkerManager.sharedInstance().unHighlightUID(UID2)
        XCTAssertNil(czzMarkerManager.sharedInstance().highlightColour(forUID: UID1))
        XCTAssertNil(czzMarkerManager.sharedInstance().highlightColour(forUID: UID2))
    }
}
