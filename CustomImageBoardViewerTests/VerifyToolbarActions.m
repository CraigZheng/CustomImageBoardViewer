//
//  VerifyToolbarActions.m
//  The navigation controller owns the toolbar it displays, so a view controller
//  must hand its items over or the buttons never appear or fire.
//

#import <XCTest/XCTest.h>
#import "czzHomeViewController.h"
#import "czzSettingsViewController.h"
#import "czzNavigationController.h"

@interface VerifyToolbarActions : XCTestCase
@end

@implementation VerifyToolbarActions

- (czzNavigationController *)presentedHome {
    czzNavigationController *nav = [czzNavigationController new];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [nav.view layoutIfNeeded];
    // viewWillAppear is where the items are handed to the nav controller.
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    [nav.topViewController beginAppearanceTransition:YES animated:NO];
    [nav.topViewController endAppearanceTransition];
    [nav.view layoutIfNeeded];
    return nav;
}

- (void)testToolbarItemsReachTheNavigationController {
    czzNavigationController *nav = [self presentedHome];
    NSLog(@"TBAR navItems=%lu vcItems=%lu", (unsigned long)nav.toolbarItems.count,
          (unsigned long)nav.topViewController.toolbarItems.count);
    XCTAssertGreaterThan(nav.toolbarItems.count, 0,
                         @"the displayed toolbar must receive the view controller items");
    XCTAssertEqual(nav.toolbarItems.count, nav.topViewController.toolbarItems.count);
}

- (void)testSettingsToolbarItemPushesTheSettingsScreen {
    czzNavigationController *nav = [self presentedHome];

    UIBarButtonItem *settings = nil;
    for (UIBarButtonItem *item in nav.toolbarItems) {
        if ([NSStringFromSelector(item.action) isEqualToString:@"settingsAction:"]) {
            settings = item;
        }
    }
    XCTAssertNotNil(settings, @"settings item must be in the displayed toolbar");

    NSUInteger before = nav.viewControllers.count;
    [settings.target performSelector:settings.action withObject:settings];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

    XCTAssertEqual(nav.viewControllers.count, before + 1, @"settings should be pushed");
    XCTAssertTrue([nav.topViewController isKindOfClass:[czzSettingsViewController class]],
                  @"top controller should be the settings screen");
}

@end
