//
//  VerifyBannerLayout.m
//  CustomImageBoardViewer
//
//  Regression tests for the constraint based banner notification.
//

#import <XCTest/XCTest.h>
#import "czzBannerNotificationUtil.h"
#import "czzBannerView.h"

@interface VerifyBannerLayout : XCTestCase
@end

@implementation VerifyBannerLayout

- (czzBannerView *)bannerInView:(UIView *)root {
    for (UIView *sub in root.subviews) {
        if ([sub isKindOfClass:[czzBannerView class]]) {
            return (czzBannerView *)sub;
        }
    }
    return nil;
}

- (UIViewController *)hostViewControllerInWindow:(UIWindow *)window {
    UIViewController *host = [UIViewController new];
    host.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = host;
    [window makeKeyAndVisible];
    [host.view layoutIfNeeded];
    return host;
}

- (void)testBannerPinsToSafeAreaBottom {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    UIViewController *host = [self hostViewControllerInWindow:window];

    [czzBannerNotificationUtil displayMessage:@"测试横幅消息" position:BannerNotificationPositionBottom];

    // Let the slide-in animation finish.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
    [host.view layoutIfNeeded];

    czzBannerView *banner = [self bannerInView:host.view];
    XCTAssertNotNil(banner, @"banner should be added to the top view controller's view");

    CGRect bannerFrame = banner.frame;
    CGRect safeFrame = host.view.safeAreaLayoutGuide.layoutFrame;
    NSLog(@"BANNER frame=%@ safe=%@", NSStringFromCGRect(bannerFrame), NSStringFromCGRect(safeFrame));

    XCTAssertEqualWithAccuracy(CGRectGetMinX(bannerFrame), CGRectGetMinX(safeFrame), 0.5, @"leading pinned to safe area");
    XCTAssertEqualWithAccuracy(CGRectGetWidth(bannerFrame), CGRectGetWidth(safeFrame), 0.5, @"trailing pinned to safe area");
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(bannerFrame), CGRectGetMaxY(safeFrame), 0.5, @"bottom pinned to safe area");
    XCTAssertGreaterThanOrEqual(CGRectGetHeight(bannerFrame), 40.0, @"intrinsic height should apply");
    XCTAssertLessThanOrEqual(CGRectGetHeight(bannerFrame), 120.0, @"intrinsic height is capped at 120");
}

- (void)testBannerSlidesInAndSettles {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    UIViewController *host = [self hostViewControllerInWindow:window];

    [czzBannerNotificationUtil displayMessage:@"动画测试" position:BannerNotificationPositionBottom];

    czzBannerView *banner = [self bannerInView:host.view];
    XCTAssertNotNil(banner, @"banner added to hierarchy");

    CGRect safeFrame = host.view.safeAreaLayoutGuide.layoutFrame;

    // The slide is a CA animation, so the layer must have an active animation
    // while the model frame has already moved to its final position.
    XCTAssertGreaterThan(banner.layer.animationKeys.count, 0U,
                         @"banner should animate into place");
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(banner.frame), CGRectGetMaxY(safeFrame), 0.5,
                               @"model frame settles on the safe area bottom");

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
    [host.view layoutIfNeeded];

    XCTAssertEqualWithAccuracy(CGRectGetMaxY(banner.frame), CGRectGetMaxY(safeFrame), 0.5,
                               @"banner stays on the safe area bottom after animation");
    XCTAssertEqualWithAccuracy(CGRectGetWidth(banner.frame), CGRectGetWidth(safeFrame), 0.5,
                               @"banner keeps the safe area width");
    XCTAssertEqual(banner.layer.animationKeys.count, 0U,
                   @"animation should be finished");
}


- (void)testBannerPinsToSafeAreaTop {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    UIViewController *host = [self hostViewControllerInWindow:window];

    [czzBannerNotificationUtil displayMessage:@"顶部横幅" position:BannerNotificationPositionTop];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
    [host.view layoutIfNeeded];

    czzBannerView *banner = [self bannerInView:host.view];
    XCTAssertNotNil(banner, @"banner should be added");

    CGRect safeFrame = host.view.safeAreaLayoutGuide.layoutFrame;
    NSLog(@"BANNER top frame=%@ safe=%@", NSStringFromCGRect(banner.frame), NSStringFromCGRect(safeFrame));

    XCTAssertEqualWithAccuracy(CGRectGetMinY(banner.frame), CGRectGetMinY(safeFrame), 0.5,
                               @"top banner sits on the safe area top");
    XCTAssertEqualWithAccuracy(CGRectGetMinX(banner.frame), CGRectGetMinX(safeFrame), 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetWidth(banner.frame), CGRectGetWidth(safeFrame), 0.5);
    XCTAssertGreaterThanOrEqual(CGRectGetHeight(banner.frame), 40.0);
}



// Direction of travel is asserted through the animated constraint constant:
// a top banner starts negative (above the safe area) and a bottom banner starts
// positive (below it), both finishing at 0. The frame is verified after settling.
- (CGFloat)offscreenStartOffsetForPosition:(BannerNotificationPosition)position {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    UIViewController *host = [self hostViewControllerInWindow:window];
    CGRect safeFrame = host.view.safeAreaLayoutGuide.layoutFrame;

    [czzBannerNotificationUtil displayMessage:@"方向测试" position:position];
    czzBannerView *banner = [self bannerInView:host.view];

    CGFloat startY = NAN;
    for (NSString *key in banner.layer.animationKeys) {
        CAAnimation *animation = [banner.layer animationForKey:key];
        if (![animation isKindOfClass:[CABasicAnimation class]]) { continue; }
        CABasicAnimation *basic = (CABasicAnimation *)animation;
        // UIKit animates the constraint as a bounds/position delta on the layer.
        if ([basic.keyPath isEqualToString:@"position"]) {
            CGPoint from = [basic.fromValue CGPointValue];
            CGPoint to = [basic.toValue CGPointValue];
            startY = from.y - to.y;
        }
    }
    [self settle:host];
    return startY;
}

- (void)settle:(UIViewController *)host {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.6]];
    [host.view layoutIfNeeded];
}

- (void)testBottomBannerStartsBelowAndSlidesUp {
    CGFloat delta = [self offscreenStartOffsetForPosition:BannerNotificationPositionBottom];
    NSLog(@"SLIDE bottom delta=%.1f", delta);
    XCTAssertFalse(isnan(delta), @"expected a position animation");
    XCTAssertGreaterThan(delta, 0, @"bottom banner starts lower and rises up");
}

- (void)testTopBannerStartsAboveAndSlidesDown {
    CGFloat delta = [self offscreenStartOffsetForPosition:BannerNotificationPositionTop];
    NSLog(@"SLIDE top delta=%.1f", delta);
    XCTAssertFalse(isnan(delta), @"expected a position animation");
    XCTAssertLessThan(delta, 0, @"top banner starts higher and drops down");
}

- (void)testBannersSettleOnTheirOwnEdge {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    UIViewController *host = [self hostViewControllerInWindow:window];
    CGRect safeFrame = host.view.safeAreaLayoutGuide.layoutFrame;

    [czzBannerNotificationUtil displayMessage:@"顶部" position:BannerNotificationPositionTop];
    [self settle:host];
    CGRect topFrame = [self bannerInView:host.view].frame;
    XCTAssertEqualWithAccuracy(CGRectGetMinY(topFrame), CGRectGetMinY(safeFrame), 0.5);

    [czzBannerNotificationUtil displayMessage:@"底部" position:BannerNotificationPositionBottom];
    [self settle:host];
    CGRect bottomFrame = [self bannerInView:host.view].frame;
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(bottomFrame), CGRectGetMaxY(safeFrame), 0.5);
    XCTAssertLessThan(CGRectGetMinY(topFrame), CGRectGetMinY(bottomFrame));
}

@end
