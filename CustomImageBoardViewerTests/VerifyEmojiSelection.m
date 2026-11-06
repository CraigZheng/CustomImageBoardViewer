//
//  VerifyEmojiSelection.m
//  Selecting the last emoticon must not read past the end of the pack.
//

#import <XCTest/XCTest.h>
#import "czzEmojiCollectionViewController.h"

@interface VerifyEmojiSelection : XCTestCase <czzEmojiCollectionViewControllerDelegate>
@property (nonatomic, assign) BOOL selected;
@end

@implementation VerifyEmojiSelection

- (void)emojiSelected:(NSString *)emoji {}
- (void)emoticonSelected:(UIImage *)emoticon { self.selected = YES; }

- (void)testSelectingPastTheEndIsIgnored {
    czzEmojiCollectionViewController *controller = [czzEmojiCollectionViewController new];
    controller.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    [controller.view layoutIfNeeded];

    UICollectionView *collectionView = controller.emojiCollectionView;
    NSInteger itemCount = [collectionView numberOfItemsInSection:0];
    XCTAssertGreaterThan(itemCount, 0, @"emo pack should have items");

    // Exactly at the end: previously <= let this through and crashed on indexing.
    NSIndexPath *outOfRange = [NSIndexPath indexPathForItem:itemCount inSection:0];
    XCTAssertNoThrow([collectionView.delegate collectionView:collectionView didSelectItemAtIndexPath:outOfRange],
                     @"out of range selection must be ignored");

    // A valid last item still works.
    self.selected = NO;
    NSIndexPath *last = [NSIndexPath indexPathForItem:itemCount - 1 inSection:0];
    XCTAssertNoThrow([collectionView.delegate collectionView:collectionView didSelectItemAtIndexPath:last]);
}

@end
