#import <XCTest/XCTest.h>
#import "czzHomeViewController.h"
@interface T7 : XCTestCase @end
@implementation T7
- (void)testSizes {
    czzHomeViewController *vc = [czzHomeViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UIWindow *w = [[UIWindow alloc] initWithFrame:CGRectMake(0,0,393,852)];
    w.rootViewController = nav;
    [w makeKeyAndVisible];
    [nav.view layoutIfNeeded];

    void (^dump)(NSString *, NSArray *) = ^(NSString *label, NSArray *items) {
        NSUInteger i = 0;
        for (UIBarButtonItem *it in items) {
            UIView *cv = it.customView;
            NSLog(@"T7 %@[%lu] custom=%@ frame=%@ bounds=%@",
                  label, (unsigned long)i++,
                  NSStringFromClass([cv class]), NSStringFromCGRect(cv.frame), NSStringFromCGRect(cv.bounds));
        }
    };
    dump(@"nav.left", vc.navigationItem.leftBarButtonItems);
    dump(@"toolbar", vc.toolbarItems);
    NSLog(@"T7 bar height=%.0f", CGRectGetHeight(nav.navigationBar.frame));
}
@end
