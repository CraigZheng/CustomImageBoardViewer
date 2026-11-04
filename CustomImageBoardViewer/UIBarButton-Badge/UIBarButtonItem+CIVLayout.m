//
//  UIBarButtonItem+CIVLayout.m
//  CustomImageBoardViewer
//

#import "UIBarButtonItem+CIVLayout.h"

// Match UIKit's NavigationButtonBar ItemWrapperView (~36pt). Absolute Auto Layout
// width/height constraints fight the wrapper's edge-pinning and cause conflicts.
static const CGFloat kCIVBarButtonSide = 36.0;

@implementation UIBarButtonItem (CIVLayout)

+ (UIButton *)civ_fixedSizeButtonWithImage:(UIImage *)image
                                    target:(id)target
                                    action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
            forState:UIControlStateNormal];
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    // Frame-based sizing only — UIKit pins customView to ItemWrapperView edges.
    button.translatesAutoresizingMaskIntoConstraints = YES;
    button.frame = CGRectMake(0, 0, kCIVBarButtonSide, kCIVBarButtonSide);
    return button;
}

+ (instancetype)civ_itemWithImage:(UIImage *)image
                           target:(id)target
                           action:(SEL)action {
    UIButton *button = [self civ_fixedSizeButtonWithImage:image target:target action:action];
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)civ_useFixedSizeCustomViewIfNeeded {
    if (self.customView || !self.image) {
        return;
    }
    UIButton *button = [UIBarButtonItem civ_fixedSizeButtonWithImage:self.image
                                                              target:self.target
                                                              action:self.action];
    button.enabled = self.enabled;
    self.image = nil;
    self.customView = button;
}

+ (void)civ_sanitizeBarButtonItems:(NSArray<UIBarButtonItem *> *)items {
    for (UIBarButtonItem *item in items) {
        [item civ_useFixedSizeCustomViewIfNeeded];
    }
}

@end

@implementation UIViewController (CIVBarButtonLayout)

- (void)civ_sanitizeBarButtonLayout {
    [UIBarButtonItem civ_sanitizeBarButtonItems:self.navigationItem.leftBarButtonItems];
    [UIBarButtonItem civ_sanitizeBarButtonItems:self.navigationItem.rightBarButtonItems];
    if (self.navigationItem.leftBarButtonItem) {
        [self.navigationItem.leftBarButtonItem civ_useFixedSizeCustomViewIfNeeded];
    }
    if (self.navigationItem.rightBarButtonItem) {
        [self.navigationItem.rightBarButtonItem civ_useFixedSizeCustomViewIfNeeded];
    }
    [UIBarButtonItem civ_sanitizeBarButtonItems:self.toolbarItems];
    if (self.navigationController.toolbarItems.count) {
        [UIBarButtonItem civ_sanitizeBarButtonItems:self.navigationController.toolbarItems];
    }
}

@end
