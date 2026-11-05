#import <XCTest/XCTest.h>
#import "czzThreadViewController.h"
#import "czzThread.h"

@interface VerifyFrames : XCTestCase
@end

@implementation VerifyFrames

- (void)testFloatingElementsDoNotOverlap {
    czzThreadViewController *controller = [czzThreadViewController new];
    czzThread *t = [czzThread new];
    t.ID = 1;
    t.content = [[NSAttributedString alloc] initWithString:@"x"];
    controller.thread = t;

    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = controller;
    [window makeKeyAndVisible];
    [controller.view layoutIfNeeded];

    UIButton *download = nil;
    UIView *imageContainer = nil;
    UIView *postContainer = nil;
    for (UIView *sub in controller.view.subviews) {
        if ([sub isKindOfClass:[UIButton class]]) download = (UIButton *)sub;
        if (CGRectGetWidth(sub.frame) == 60 && CGRectGetHeight(sub.frame) == 60) {
            if (!imageContainer) imageContainer = sub; else postContainer = sub;
        }
    }
    NSLog(@"FRAMES download=%@", NSStringFromCGRect(download.frame));
    NSLog(@"FRAMES image=%@", NSStringFromCGRect(imageContainer.frame));
    NSLog(@"FRAMES post=%@", NSStringFromCGRect(postContainer.frame));
    NSLog(@"FRAMES safeArea=%@", NSStringFromUIEdgeInsets(controller.view.safeAreaInsets));

    // Geometry from the retired scene: download 40 wide with a 30pt trailing inset,
    // containers 60 wide with a 20pt trailing inset.
    CGFloat width = CGRectGetWidth(controller.view.bounds);
    XCTAssertEqualWithAccuracy(CGRectGetWidth(download.frame), 40, 0.5,
                               @"download button should be 40pt wide");
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(download.frame), width - 30, 0.5,
                               @"download button 30pt from trailing edge");
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(imageContainer.frame), width - 20, 0.5,
                               @"containers 20pt from trailing edge");
    XCTAssertEqualWithAccuracy(CGRectGetWidth(imageContainer.frame), 60, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(postContainer.frame), width - 20, 0.5);
    // The button is narrower, so its leading edge sits inside the containers'.
    XCTAssertGreaterThan(CGRectGetMinX(download.frame), CGRectGetMinX(imageContainer.frame));
    XCTAssertLessThanOrEqual(CGRectGetMaxX(download.frame), CGRectGetWidth(controller.view.bounds) + 0.5);
    XCTAssertLessThanOrEqual(CGRectGetMaxY(download.frame), CGRectGetHeight(controller.view.bounds) + 0.5);
    // Containers sit above the download button.
    XCTAssertLessThanOrEqual(CGRectGetMaxY(imageContainer.frame), CGRectGetMinY(download.frame) + 0.5);
    XCTAssertLessThanOrEqual(CGRectGetMaxY(postContainer.frame), CGRectGetMinY(imageContainer.frame) + 0.5);
    // And the image container must not be to the left of the download button's left edge beyond tolerance.
    XCTAssertEqualWithAccuracy(CGRectGetMinX(imageContainer.frame), CGRectGetMinX(postContainer.frame), 0.5);
}

@end
