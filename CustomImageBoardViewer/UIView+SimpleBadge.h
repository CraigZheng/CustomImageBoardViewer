//
//  UIView+SimpleBadge.h
//  CustomImageBoardViewer
//
//  Minimal badge accessory that replaces UIView+MGBadgeView.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SimpleBadgePosition) {
    SimpleBadgePositionTopRight = 0
};

@interface SimpleBadgeView : UILabel
@property (nonatomic, assign) SimpleBadgePosition position;
@property (nonatomic, strong) UIColor *badgeColor;
@property (nonatomic, assign) NSInteger badgeValue;
@end

@interface UIView (SimpleBadge)
@property (nonatomic, readonly) SimpleBadgeView *badgeView;
@end

// Compatibility aliases for existing call sites.
typedef SimpleBadgePosition MGBadgePosition;
static const MGBadgePosition MGBadgePositionTopRight = SimpleBadgePositionTopRight;

NS_ASSUME_NONNULL_END
