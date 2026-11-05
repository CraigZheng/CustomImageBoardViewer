#import <XCTest/XCTest.h>
#import "czzThreadViewController.h"
#import "czzThread.h"

@interface VerifyDownloadButton : XCTestCase
@end

@implementation VerifyDownloadButton

// The massive download button used to be created with hidden = YES, no image and
// no target, so it could never appear or be tapped. This asserts all three are set.
- (void)testMassiveDownloadButtonIsReachable {
    czzThread *thread = [czzThread new];
    thread.ID = 1;
    thread.content = [[NSAttributedString alloc] initWithString:@"x"];

    czzThreadViewController *controller = [czzThreadViewController new];
    controller.thread = thread;
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = controller;
    [window makeKeyAndVisible];
    [controller.view layoutIfNeeded];

    UIButton *downloadButton = nil;
    for (UIView *subview in controller.view.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            downloadButton = (UIButton *)subview;
        }
    }

    XCTAssertNotNil(downloadButton, @"massive download button should be in the view hierarchy");
    XCTAssertFalse(downloadButton.isHidden, @"button must not be permanently hidden");
    XCTAssertNotNil(downloadButton.imageView.image, @"download icon must be set");
    XCTAssertTrue([downloadButton.allTargets containsObject:controller],
                  @"button must target the controller's massiveDownloadAction:");
}

@end
