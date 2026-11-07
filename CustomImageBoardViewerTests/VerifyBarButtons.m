//
//  VerifyBarButtons.m
//  Storyboard supplied bar buttons had images and targets. The converted screens
//  run their items through civ_sanitizeBarButtonLayout, which replaces images with
//  fixed size custom buttons, so an item is usable when it renders a view and
//  carries an action.
//

#import <XCTest/XCTest.h>
#import "czzHomeViewController.h"
#import "czzThreadViewController.h"
#import "czzThread.h"

@interface VerifyBarButtons : XCTestCase
@end

@implementation VerifyBarButtons

- (UIView *)layout:(UIViewController *)controller {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [nav.view layoutIfNeeded];
    [controller.view layoutIfNeeded];
    return controller.view;
}

- (BOOL)isFlexibleSpace:(UIBarButtonItem *)item {
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                         target:nil action:nil];
    return [item isEqual:flex];
}

/// An action item must render something and do something.
- (void)assertItemIsUsable:(UIBarButtonItem *)item name:(NSString *)name {
    if ([self isFlexibleSpace:item]) {
        return; // spacers are intentionally blank
    }
    BOOL rendersView = item.image != nil || item.title.length > 0 || item.customView != nil;
    // A bar item that hosts a custom view forwards taps through that view, so it
    // carries no target/action of its own.
    BOOL hasOwnAction = item.action != nil && item.target != nil;
    BOOL customViewHandlesTaps = [item.customView isKindOfClass:[UIControl class]] &&
        ((UIControl *)item.customView).allTargets.count > 0;
    BOOL hasAction = hasOwnAction || customViewHandlesTaps;
    NSLog(@"BARBUTTON %@ renders=%d ownAction=%@ customTaps=%d",
          name, rendersView, NSStringFromSelector(item.action), customViewHandlesTaps);
    XCTAssertTrue(rendersView, @"%@ renders nothing", name);
    XCTAssertTrue(hasAction, @"%@ has no target or action", name);
}

- (void)testHomeBarItemsAreUsable {
    czzHomeViewController *controller = [czzHomeViewController new];
    [self layout:controller];

    NSUInteger index = 0;
    for (UIBarButtonItem *item in controller.navigationItem.leftBarButtonItems) {
        [self assertItemIsUsable:item name:[NSString stringWithFormat:@"home.left[%lu]", (unsigned long)index++]];
    }
    [self assertItemIsUsable:controller.navigationItem.rightBarButtonItem name:@"home.right"];

    index = 0;
    for (UIBarButtonItem *item in controller.toolbarItems) {
        [self assertItemIsUsable:item name:[NSString stringWithFormat:@"home.toolbar[%lu]", (unsigned long)index++]];
    }
}

- (void)testThreadBarItemsAreUsable {
    czzThread *thread = [czzThread new];
    thread.ID = 1;
    thread.content = [[NSAttributedString alloc] initWithString:@"x"];
    czzThreadViewController *controller = [czzThreadViewController new];
    controller.thread = thread;
    [self layout:controller];

    NSUInteger index = 0;
    for (UIBarButtonItem *item in controller.toolbarItems) {
        [self assertItemIsUsable:item name:[NSString stringWithFormat:@"thread.toolbar[%lu]", (unsigned long)index++]];
    }
    XCTAssertNotNil(controller.navigationItem.rightBarButtonItem, @"PO switch bar item");
}

@end
