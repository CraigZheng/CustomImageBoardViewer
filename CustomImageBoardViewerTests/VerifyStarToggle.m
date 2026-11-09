//
//  VerifyStarToggle.m
//  The star's image used to be written to the UIBarButtonItem while the visible
//  glyph lived in the custom view the iOS 26 sanitizer had swapped in, so the
//  toggle never changed on screen.
//

#import <XCTest/XCTest.h>
#import "czzThreadViewController.h"
#import "czzThread.h"

@interface VerifyStarToggle : XCTestCase
@end

@implementation VerifyStarToggle

- (czzThreadViewController *)controller {
    czzThread *t = [czzThread new];
    t.ID = 1;
    t.content = [[NSAttributedString alloc] initWithString:@"x"];
    czzThreadViewController *vc = [czzThreadViewController new];
    vc.thread = t;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [vc.view layoutIfNeeded];
    return vc;
}

- (UIImage *)visibleStarImage:(czzThreadViewController *)vc {
    if ([vc.starButton.customView isKindOfClass:[UIButton class]]) {
        return [(UIButton *)vc.starButton.customView imageForState:UIControlStateNormal];
    }
    return vc.starButton.image;
}

// The sanitizer must have converted the item, otherwise this test asserts nothing.
- (void)testStarItemWasSanitizedIntoACustomView {
    czzThreadViewController *vc = [self controller];
    XCTAssertNotNil(vc.starButton.customView, @"star should carry a custom view");
    XCTAssertTrue([vc.starButton.customView isKindOfClass:[UIButton class]]);
    XCTAssertNil(vc.starButton.image, @"the item image is dead once sanitized");
}

// Drive the update twice: the glyph must actually change on the custom view.
- (void)testStarGlyphChangesWithFavouriteState {
    czzThreadViewController *vc = [self controller];
    UIImage *initial = [self visibleStarImage:vc];
    XCTAssertNotNil(initial, @"star should show an image");

    // Toggle the underlying state through the same action the button fires.
    [vc starAction:nil];
    UIImage *afterToggle = [self visibleStarImage:vc];
    NSLog(@"STARGLYPH initial=%@ after=%@", initial, afterToggle);
    XCTAssertNotNil(afterToggle);
    XCTAssertEqualObjects(afterToggle, [UIImage imageNamed:@"solid_star.png"],
                          @"the glyph must become solid_star once favourited");

    // And back again.
    [vc starAction:nil];
    UIImage *restored = [self visibleStarImage:vc];
    XCTAssertEqualObjects(restored, [UIImage imageNamed:@"star.png"],
                          @"toggling again returns to the hollow star");
}

@end
