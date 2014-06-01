//
//  CustomImageBoardViewerTests.m
//  CustomImageBoardViewerTests
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "czzNotification.h"
#import "SMXMLDocument.h"

@interface CustomImageBoardViewerTests : XCTestCase

@end

@implementation CustomImageBoardViewerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNotification
{
    NSError *error;
    NSString *xmlString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://civ.atwebpages.com/test.xml"] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"error %@", error);
    }
    SMXMLDocument *xmlDoc = [SMXMLDocument documentWithData:[xmlString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    czzNotification *notification;
    for (SMXMLElement *element in xmlDoc.root.children) {
        if ([element.name isEqualToString:@"message"]) {
            notification = [[czzNotification alloc] initWithXMLElement:element];
        }
    }
    
    XCTAssertNotNil(notification, @"notification not inited");
    XCTAssertNotEqual(notification.sender, [czzNotification new].sender, @"content equal!");
    
}

@end
