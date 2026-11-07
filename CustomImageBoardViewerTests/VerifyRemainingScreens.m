//
//  VerifyRemainingScreens.m
//  The other controllers rebuilt in code: none may come up with nil outlets or
//  a collapsed layout.
//

#import <XCTest/XCTest.h>
#import "czzCookieManagerViewController.h"
#import "czzFavouriteManagerViewController.h"
#import "czzPostViewController.h"
#import "czzMiniThreadViewController.h"
#import "czzOnScreenCommandViewController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "czzPostSenderManagerViewController.h"
#import "czzShortImageManagerCollectionViewController.h"
#import "czzMessagePopUpViewController.h"
#import "czzNotificationBannerViewController.h"
#import "czzThreadViewController.h"
#import "czzThread.h"

@interface VerifyRemainingScreens : XCTestCase
@end

@implementation VerifyRemainingScreens

- (UIView *)layout:(UIViewController *)controller {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [nav.view layoutIfNeeded];
    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
    return controller.view;
}

/// The root view must have real size and at least one visible subview.
- (void)assertRenders:(UIViewController *)controller name:(NSString *)name {
    UIView *view = [self layout:controller];
    NSUInteger visible = 0;
    for (UIView *sub in view.subviews) {
        if (!sub.isHidden && CGRectGetWidth(sub.frame) > 0 && CGRectGetHeight(sub.frame) > 0) {
            visible++;
        }
    }
    NSLog(@"SCREEN %@ root=%@ subviews=%lu visible=%lu",
          name, NSStringFromCGRect(view.bounds), (unsigned long)view.subviews.count, (unsigned long)visible);
    XCTAssertGreaterThan(CGRectGetWidth(view.bounds), 0, @"%@ has no root view", name);
    XCTAssertGreaterThan(visible, 0, @"%@ renders nothing visible", name);
}

- (void)testThreadWatchAndCounterAreWired {
    czzThread *thread = [czzThread new];
    thread.ID = 1;
    thread.content = [[NSAttributedString alloc] initWithString:@"x"];
    czzThreadViewController *controller = [czzThreadViewController new];
    controller.thread = thread;
    [self layout:controller];

    // Both were written to during updateTableView but never created.
    XCTAssertNotNil(controller.watchButton, @"watch button must exist for updateTableView");
    XCTAssertNotNil(controller.jumpBarButtonItem, @"advance button must exist for updateTableView");
    XCTAssertNotNil(controller.jumpBarButtonItem.customView,
                    @"advance hosts the round button that shows the page number");
    XCTAssertTrue([controller.toolbarItems containsObject:controller.watchButton],
                  @"watch button belongs in the toolbar");
}

- (void)testCookieManagerRenders {
    [self assertRenders:[czzCookieManagerViewController new] name:@"cookieManager"];
}

- (void)testFavouriteManagerRenders {
    [self assertRenders:[czzFavouriteManagerViewController new] name:@"favouriteManager"];
}

- (void)testPostViewControllerRenders {
    [self assertRenders:[czzPostViewController new] name:@"postView"];
}

- (void)testOnScreenCommandRenders {
    czzOnScreenCommandViewController *controller = [czzOnScreenCommandViewController new];
    [self assertRenders:controller name:@"onScreenCommand"];
}

- (void)testOnScreenImageManagerRenders {
    czzOnScreenImageManagerViewController *controller = [czzOnScreenImageManagerViewController new];
    [self assertRenders:controller name:@"imageManager"];
    XCTAssertNotNil(controller.mainIcon, @"icon built");
    XCTAssertNotNil(controller.mainIconContainer);
}

- (void)testPostSenderManagerRenders {
    [self assertRenders:[czzPostSenderManagerViewController new] name:@"postSenderManager"];
}

- (void)testShortImageManagerRenders {
    [self assertRenders:[czzShortImageManagerCollectionViewController new] name:@"shortImageManager"];
}

- (void)testMessagePopupRenders {
    [self assertRenders:[czzMessagePopUpViewController new] name:@"messagePopup"];
}

- (void)testNotificationBannerRenders {
    [self assertRenders:[czzNotificationBannerViewController new] name:@"notificationBanner"];
}

@end
