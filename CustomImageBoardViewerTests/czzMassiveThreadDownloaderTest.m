//
//  czzMassiveThreadDownloaderTest.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "czzMassiveThreadDownloader.h"

@interface czzMassiveThreadDownloaderTest : XCTestCase <czzMassiveThreadDownloaderDelegate>

@end

@implementation czzMassiveThreadDownloaderTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

#pragma mark - czzMassiveThreadDownloaderDelegate
- (void)threadDownloaderDownloadUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress {
    
}

- (void)pageNumberUpdated:(NSInteger)currentPage allPage:(NSInteger)allPage {
    
}

- (void)massiveDownloader:(czzMassiveThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads errors:(NSArray *)errors {
    
}

@end
