//
//  VerifyPostSenderModes.m
//  An unconfigured post sender must fail through the delegate, not raise.
//

#import <XCTest/XCTest.h>
#import "czzPostSender.h"

@interface VerifyPostSenderModes : XCTestCase <czzPostSenderDelegate>
@property (nonatomic, strong) XCTestExpectation *failureExpectation;
@property (nonatomic, assign) BOOL didFail;
@end

@implementation VerifyPostSenderModes

- (void)postSender:(czzPostSender *)postSender completedPosting:(BOOL)success message:(NSString *)message response:(id)response {
    self.didFail = YES;
    [self.failureExpectation fulfill];
}

- (void)testUnknownModeReportsFailureInsteadOfRaising {
    czzPostSender *sender = [czzPostSender new];
    sender.postMode = postSenderModeUnknown;
    sender.delegate = self;
    self.failureExpectation = [self expectationWithDescription:@"delegate failure"];

    XCTAssertNoThrow([sender sendPost], @"sending with an unknown mode must not raise");
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(self.didFail, @"the sender should report the failure to its delegate");
}

@end
