//
//  UIViewController+ChildContainer.m
//  CustomImageBoardViewer
//

#import "UIViewController+ChildContainer.h"

@implementation UIViewController (ChildContainer)

- (void)civ_addChildViewController:(UIViewController *)child toContainer:(UIView *)container {
    if (!child || !container) {
        return;
    }
    [self addChildViewController:child];
    child.view.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:child.view];
    [NSLayoutConstraint activateConstraints:@[
        [child.view.topAnchor constraintEqualToAnchor:container.topAnchor],
        [child.view.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [child.view.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [child.view.trailingAnchor constraintEqualToAnchor:container.trailingAnchor]
    ]];
    [child didMoveToParentViewController:self];
}

@end
