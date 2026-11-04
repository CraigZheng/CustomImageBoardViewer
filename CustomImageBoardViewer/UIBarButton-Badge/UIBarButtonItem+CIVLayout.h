//
//  UIBarButtonItem+CIVLayout.h
//  CustomImageBoardViewer
//
//  Avoids iOS 26 UIKit zero-width ButtonWrapper conflicts for image/system bar items.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (CIVLayout)

+ (instancetype)civ_itemWithImage:(UIImage *)image
                           target:(nullable id)target
                           action:(nullable SEL)action;

+ (UIButton *)civ_fixedSizeButtonWithImage:(UIImage *)image
                                    target:(nullable id)target
                                    action:(nullable SEL)action;

/// Convert an image-based item to a fixed-size customView in place (keeps IBOutlets).
- (void)civ_useFixedSizeCustomViewIfNeeded;

+ (void)civ_sanitizeBarButtonItems:(nullable NSArray<UIBarButtonItem *> *)items;

@end

@interface UIViewController (CIVBarButtonLayout)

/// Sanitize navigation + toolbar image bar buttons for the iOS 26 layout bug.
- (void)civ_sanitizeBarButtonLayout;

@end

NS_ASSUME_NONNULL_END
