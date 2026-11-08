//
//  VerifyUIConversion.m
//  Smoke tests over the view controllers that were rebuilt in code.
//

#import <XCTest/XCTest.h>
#import "czzHomeViewController.h"
#import "czzThreadViewController.h"
#import "czzSettingsViewController.h"
#import "czzFeedbackViewController.h"
#import "czzMoreInfoViewController.h"
#import "czzThread.h"
#import "czzForumsViewController.h"

@interface VerifyUIConversion : XCTestCase
@end

@implementation VerifyUIConversion

/// Lays the controller out at phone size and returns its root view.
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

/// Any view with a zero width or height that is not intentionally collapsed.
- (void)assertNoDegenerateFrames:(UIView *)root labelled:(NSString *)label
                       allowZero:(BOOL)allowZero {
    for (UIView *sub in root.subviews) {
        if (sub.isHidden) { [self assertNoDegenerateFrames:sub labelled:label allowZero:allowZero]; continue; }
        if (allowZero) { continue; }
        if (CGRectGetWidth(sub.frame) == 0 && CGRectGetHeight(sub.frame) == 0) {
            XCTFail(@"%@: %@ has a zero frame", label, NSStringFromClass([sub class]));
        }
        [self assertNoDegenerateFrames:sub labelled:label allowZero:allowZero];
    }
}


- (void)testSettingsControllerRowsBuild {
    czzSettingsViewController *controller = [czzSettingsViewController new];
    [self layout:controller];
    UITableView *table = controller.settingsTableView;
    XCTAssertNotNil(table);
    XCTAssertEqual(table.numberOfSections, 2);
    // Build every row to prove the cell factories never return a blank cell.
    for (NSInteger section = 0; section < table.numberOfSections; section++) {
        for (NSInteger row = 0; row < [table numberOfRowsInSection:section]; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell *cell = [controller tableView:table cellForRowAtIndexPath:indexPath];
            XCTAssertNotNil(cell, @"row %ld-%ld built no cell", (long)section, (long)row);
            XCTAssertGreaterThan(cell.contentView.subviews.count, 0,
                                 @"row %ld-%ld has no content", (long)section, (long)row);
        }
    }
}

- (void)testFeedbackControllerLayout {
    czzFeedbackViewController *controller = [czzFeedbackViewController new];
    UIView *view = [self layout:controller];
    XCTAssertNotNil(controller.contentTextView, @"text view built");
    XCTAssertGreaterThan(CGRectGetHeight(controller.contentTextView.frame), 100);
    XCTAssertLessThanOrEqual(CGRectGetMaxY(controller.contentTextView.frame),
                             CGRectGetHeight(view.bounds) + 1);
}

- (void)testMoreInfoControllerLayout {
    czzMoreInfoViewController *controller = [czzMoreInfoViewController new];
    [self layout:controller];
    XCTAssertNotNil(controller.containerScrollView);
    XCTAssertNotNil(controller.coverImageWebView);
    XCTAssertNotNil(controller.headerTextWebView);
    XCTAssertGreaterThan(CGRectGetHeight(controller.containerScrollView.frame), 100);
    XCTAssertNotNil(controller.moreInfoNavItem, @"navigation item must survive");
}

- (void)testHomeAndThreadControllersLayout {
    czzHomeViewController *home = [czzHomeViewController new];
    UIView *homeView = [self layout:home];
    XCTAssertNotNil(home.threadTableView);
    XCTAssertGreaterThan(CGRectGetHeight(home.threadTableView.frame), 100);
    XCTAssertLessThanOrEqual(CGRectGetMaxY(home.threadTableView.frame),
                             CGRectGetHeight(homeView.bounds) + 1);

    czzThread *thread = [czzThread new];
    thread.ID = 1;
    thread.content = [[NSAttributedString alloc] initWithString:@"x"];
    czzThreadViewController *threadVC = [czzThreadViewController new];
    threadVC.thread = thread;
    [self layout:threadVC];
    XCTAssertNotNil(threadVC.threadTableView);
    XCTAssertGreaterThan(CGRectGetHeight(threadVC.threadTableView.frame), 100);
}


- (void)testTablesStayInsideTheSafeArea {
    // Every list screen must keep its table clear of the navigation bar and the
    // toolbar; anchoring to rootView.top lets the bar cover the first rows.
    czzSettingsViewController *settings = [czzSettingsViewController new];
    UIView *settingsRoot = [self layout:settings];
    XCTAssertGreaterThanOrEqual(CGRectGetMinY(settings.settingsTableView.frame),
                                settingsRoot.safeAreaInsets.top - 0.5,
                                @"settings table must start below the navigation bar");

    czzHomeViewController *home = [czzHomeViewController new];
    UIView *homeRoot = [self layout:home];
    XCTAssertGreaterThanOrEqual(CGRectGetMinY(home.threadTableView.frame),
                                homeRoot.safeAreaInsets.top - 0.5,
                                @"home table must start below the navigation bar");
}


- (void)testForumPickedNotificationIgnoresEmptyPayload {
    // The handler used to raise when the payload had neither a forum nor a timeline.
    czzHomeViewController *home = [czzHomeViewController new];
    [self layout:home];
    XCTAssertNoThrow([[NSNotificationCenter defaultCenter]
                      postNotificationName:kForumPickedNotification
                      object:nil
                      userInfo:nil],
                     @"an empty payload must be ignored, not raise");
}

@end
