//
//  czzMassiveThreadDownloaderTest.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "czzMassiveThreadDownloader.h"
#import "czzThread.h"

@interface czzMassiveThreadDownloaderTest : XCTestCase <czzMassiveThreadDownloaderDelegate>
@property (nonatomic, strong) czzMassiveThreadDownloader *massiveDownloader;
@property (nonatomic, strong) XCTestExpectation *expectation;
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

- (void)testMassiveDownloader {
    self.expectation = [self expectationWithDescription:@""];
    // Use thie thread: 4214593
    self.massiveDownloader = [[czzMassiveThreadDownloader alloc] initWithForum:nil
                                                                     andThread:[[czzThread alloc] initWithParentID:4214593]];
    self.massiveDownloader.delegate = self;
    [self.massiveDownloader start];
    [self waitForExpectationsWithTimeout:120 handler:nil];
}

#pragma mark - czzMassiveThreadDownloaderDelegate
- (void)threadDownloaderDownloadUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress {
    XCTAssert(downloader.parentThread.responseCount == 66);
}

- (void)pageNumberUpdated:(NSInteger)currentPage allPage:(NSInteger)allPage {
    DLog(@"%ld - %ld - %ld", (long)currentPage, (long)allPage, (long)self.massiveDownloader.pageNumber);
    XCTAssert(currentPage == self.massiveDownloader.pageNumber);
    XCTAssert(allPage == 4);
}

- (void)massiveDownloader:(czzMassiveThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads errors:(NSArray *)errors {
    XCTAssert(success);
    XCTAssert(threads.count == downloader.parentThread.responseCount);
    XCTAssert(errors.count == 0);
    [self.expectation fulfill];
}

- (void)massiveDownloaderUpdated:(czzMassiveThreadDownloader *)downloader {
    XCTAssert(downloader == self.massiveDownloader);
}

@end
