//
//  VerifyObserverLifecycle.m
//  Block based observers must be removed, otherwise the centre keeps the block
//  and the controller it captures.
//

#import <XCTest/XCTest.h>
#import "czzPostViewController.h"

@interface VerifyObserverLifecycle : XCTestCase
@end

@implementation VerifyObserverLifecycle

- (void)testPostControllerReleasesItsObserver {
    __weak czzPostViewController *weakController = nil;
    @autoreleasepool {
        czzPostViewController *controller = [czzPostViewController new];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
        window.rootViewController = nav;
        [window makeKeyAndVisible];
        [controller.view layoutIfNeeded];
        weakController = controller;
        // Window is torn down at the end of this autorelease pool.
        window.rootViewController = nil;
    }

    // Give the run loop a moment to release the view controller.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    XCTAssertNil(weakController, @"post controller should be deallocated once its observers are removed");
}

@end
