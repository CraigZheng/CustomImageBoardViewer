//
//  UIViewController+ChildContainer.h
//  CustomImageBoardViewer
//

#import <UIKit/UIKit.h>

@interface UIViewController (ChildContainer)

/// Adds `child` as a child view controller and pins its view to `container`.
/// The container must already be in the hierarchy and use Auto Layout.
- (void)civ_addChildViewController:(UIViewController *)child toContainer:(UIView *)container;

@end
