//
//  VerifyThreadNavigationBar.m
//  A pushed thread view must keep the system back button; assigning a leading bar
//  button item would replace it.
//

#import <XCTest/XCTest.h>
#import "czzThreadViewController.h"
#import "czzHomeViewController.h"
#import "czzThread.h"

@interface VerifyThreadNavigationBar : XCTestCase
@end

@implementation VerifyThreadNavigationBar

- (czzThreadViewController *)pushedThreadController {
    czzHomeViewController *home = [czzHomeViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:home];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [nav.view layoutIfNeeded];

    czzThread *thread = [czzThread new];
    thread.ID = 1;
    thread.content = [[NSAttributedString alloc] initWithString:@"x"];
    czzThreadViewController *threadVC = [czzThreadViewController new];
    threadVC.thread = thread;
    [nav pushViewController:threadVC animated:NO];
    [nav.view layoutIfNeeded];
    return threadVC;
}

- (void)testThreadViewKeepsItsBackButton {
    czzThreadViewController *controller = [self pushedThreadController];

    XCTAssertNil(controller.navigationItem.leftBarButtonItem,
                 @"a leading bar button item replaces the system back button");
    XCTAssertNil(controller.navigationItem.leftBarButtonItems,
                 @"leading bar button items replace the system back button");
    XCTAssertFalse(controller.navigationItem.hidesBackButton,
                   @"the back button must not be hidden");
    XCTAssertGreaterThan(controller.navigationController.viewControllers.count, 1,
                         @"the thread view should be pushed, not presented");
    NSLog(@"NAVBAR left=%@ right=%@ items=%lu",
          controller.navigationItem.leftBarButtonItem,
          controller.navigationItem.rightBarButtonItem,
          (unsigned long)controller.navigationController.viewControllers.count);
}

- (void)testAdvanceButtonCarriesThePageNumber {
    czzThreadViewController *controller = [self pushedThreadController];
    UIBarButtonItem *advance = controller.jumpBarButtonItem;
    XCTAssertNotNil(advance, @"the advance button exists");
    XCTAssertNotNil(advance.customView, @"advance shows the page number in a round button");
    XCTAssertTrue([advance.customView isKindOfClass:[UIButton class]],
                  @"advance button hosts a UIButton so it can show a number");
    XCTAssertTrue([controller.toolbarItems containsObject:advance],
                  @"advance with the page number belongs in the toolbar");
    // Six actions (reply, star, watch, upload, advance, report) and five spacers;
    // the separate counter item is gone, which leaves this one short of twelve.
    XCTAssertEqual(controller.toolbarItems.count, 11, @"six actions plus five spacers");
}

@end
