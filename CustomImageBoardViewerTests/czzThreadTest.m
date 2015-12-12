//
//  czzThreadTest.m
//  CustomImageBoardViewer
//
//  Created by Craig on 11/12/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "czzThread.h"

@interface czzThreadTest : XCTestCase
@property (nonatomic, readonly) NSString *listingJson;
@property (nonatomic, readonly) NSString *contentJson;
@end

@implementation czzThreadTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThreadListing {
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:[self.listingJson dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    XCTAssert(jsonArray.count == 20);
    for (NSDictionary *dict in jsonArray) {
        czzThread *thread = [[czzThread alloc] initWithJSONDictionary:dict];
        XCTAssert(thread.content.length);
        XCTAssert([thread.postDateTime compare:[NSDate dateWithTimeIntervalSince1970:0]] != NSOrderedSame);
        XCTAssertFalse([thread.thImgSrc isEqualToString:thread.imgSrc]);
        
    }
}

#pragma mark - Getters

- (NSString *)listingJson {
    NSString *listingJson = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Threads" ofType:@"json"]
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
    return listingJson;
}

- (NSString *)contentJson {
    NSString *contentJson = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"ThreadContent" ofType:@"json"]
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
    return contentJson;
}

@end
