//
//  VerifyUIResizing.m
//  The converted screens must reflow when the container is not phone-portrait sized.
//

#import <XCTest/XCTest.h>
#import "czzHomeViewController.h"
#import "czzThreadViewController.h"
#import "czzSettingsViewController.h"
#import "czzSearchViewController.h"
#import "czzFeedbackViewController.h"
#import "czzThread.h"

@interface VerifyUIResizing : XCTestCase
@end

@implementation VerifyUIResizing

/// Lays the controller out at an arbitrary size and returns the view.
- (UIView *)layoutController:(UIViewController *)controller size:(CGSize)size {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    nav.view.frame = CGRectMake(0, 0, size.width, size.height);
    [nav.view layoutIfNeeded];
    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
    return controller.view;
}


- (void)testScreensReflowOnIPadAndLandscape {
    NSArray *sizes = @[
        [NSValue valueWithCGSize:CGSizeMake(320, 568)],   // small phone
        [NSValue valueWithCGSize:CGSizeMake(834, 1112)],  // iPad portrait
        [NSValue valueWithCGSize:CGSizeMake(852, 393)],   // landscape
    ];

    for (NSValue *value in sizes) {
        CGSize size = value.CGSizeValue;
        NSString *label = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];

        czzSearchViewController *search = [czzSearchViewController new];
        UIView *searchRoot = [self layoutController:search size:size];
        NSLog(@"RESIZE %@ search view=%@ web=%@", label,
              NSStringFromCGRect(searchRoot.bounds),
              NSStringFromCGRect(search.searchWebView.frame));
        XCTAssertEqualWithAccuracy(CGRectGetWidth(search.searchWebView.frame),
                                   size.width, 1.0,
                                   @"%@: search web view must match container width", label);

        czzSettingsViewController *settings = [czzSettingsViewController new];
        UIView *settingsRoot = [self layoutController:settings size:size];
        NSLog(@"RESIZE %@ settings view=%@ table=%@", label,
              NSStringFromCGRect(settingsRoot.bounds),
              NSStringFromCGRect(settings.settingsTableView.frame));
        XCTAssertEqualWithAccuracy(CGRectGetWidth(settings.settingsTableView.frame),
                                   size.width, 1.0,
                                   @"%@: settings table must match container width", label);

        czzHomeViewController *home = [czzHomeViewController new];
        UIView *homeRoot = [self layoutController:home size:size];
        NSLog(@"RESIZE %@ home view=%@ table=%@", label,
              NSStringFromCGRect(homeRoot.bounds),
              NSStringFromCGRect(home.threadTableView.frame));
        XCTAssertEqualWithAccuracy(CGRectGetWidth(home.threadTableView.frame),
                                   size.width, 1.0,
                                   @"%@: home table must match container width", label);
    }
}

@end
