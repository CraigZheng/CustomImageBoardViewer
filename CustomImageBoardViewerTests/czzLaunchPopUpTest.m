//
//  czzLaunchPopUpTest.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "czzLaunchPopUpNotification.h"

@interface czzLaunchPopUpTest : XCTestCase

@end

@implementation czzLaunchPopUpTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitWithJson {
    NSString *jsonString = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"popup notification example" ofType:@"json"]
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    czzLaunchPopUpNotification *notification = [[czzLaunchPopUpNotification alloc]
                                                initWithJson:jsonString];
    XCTAssert(notification);
    XCTAssert(notification.enable);
    XCTAssert(notification.notificationContent.length);
    XCTAssert(notification.notificationDate);
}

@end
