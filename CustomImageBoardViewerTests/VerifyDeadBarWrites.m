//
//  VerifyDeadBarWrites.m
//  Writes to UIBarButton properties that the iOS 26 sanitizer has disconnected.
//

#import <XCTest/XCTest.h>
#import "czzThreadViewController.h"
#import "czzHomeViewController.h"
#import "czzPostViewController.h"
#import "czzThread.h"
#import "czzPostSender.h"

@interface VerifyDeadBarWrites : XCTestCase
@end

@implementation VerifyDeadBarWrites

- (void)layout:(UIViewController *)vc {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [nav.view layoutIfNeeded];
}

// jumpBarButtonItem.enabled: the item wraps a custom view, so the enabled flag
// has no effect on the wrapped button. Check the wrapped button's own state.
- (void)testJumpEnableWriteReachesTheButton {
    czzThread *t = [czzThread new]; t.ID = 1;
    t.content = [[NSAttributedString alloc] initWithString:@"x"];
    czzThreadViewController *vc = [czzThreadViewController new];
    vc.thread = t;
    [self layout:vc];
    XCTAssertTrue([vc.jumpBarButtonItem.customView isKindOfClass:[UIButton class]]);
    UIButton *button = (UIButton *)vc.jumpBarButtonItem.customView;

    vc.jumpBarButtonItem.enabled = NO;
    NSLog(@"DEADWRITE item.enabled=%d button.enabled=%d after item NO",
          (int)vc.jumpBarButtonItem.isEnabled, (int)button.isEnabled);
    XCTAssertEqual(button.isEnabled, NO,
                   @"disabling the item must disable the visible button");

    vc.jumpBarButtonItem.enabled = YES;
    XCTAssertEqual(button.isEnabled, YES, @"re-enabling must reach the visible button");
}

// czzPostViewController: display-only mode disables every toolbar item. Those
// items are civ_ custom-view items, so the enabled write may be dead there too.
- (void)testPostDisplayOnlyDisablesButtons {
    czzPostViewController *vc = [czzPostViewController new];
    vc.postMode = postViewControllerModeDisplayOnly;
    // renderContent asserts displayPostSender in display-only mode.
    czzPostSender *sender = [czzPostSender new];
    sender.content = @"display only";
    vc.displayPostSender = sender;
    [self layout:vc];
    // renderContent builds the accessory toolbar and disables the items.
    [vc performSelector:@selector(renderContent)];

    UIToolbar *accessory = (UIToolbar *)vc.postTextView.inputAccessoryView;
    XCTAssertNotNil(accessory, @"post view should install an accessory toolbar");
    for (UIBarButtonItem *item in accessory.items) {
        if (item.customView && [item.customView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)item.customView;
            NSLog(@"DEADWRITE post item.enabled=%d button.enabled=%d",
                  (int)item.isEnabled, (int)button.isEnabled);
            XCTAssertEqual(button.isEnabled, NO,
                           @"display-only mode must disable the visible button");
        }
    }
}

@end
