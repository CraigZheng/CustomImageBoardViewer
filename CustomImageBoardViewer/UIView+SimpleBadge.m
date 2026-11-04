//
//  UIView+SimpleBadge.m
//  CustomImageBoardViewer
//

#import "UIView+SimpleBadge.h"
#import <objc/runtime.h>

static const void *kSimpleBadgeViewKey = &kSimpleBadgeViewKey;

@implementation SimpleBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.position = SimpleBadgePositionTopRight;
        self.badgeColor = [UIColor redColor];
        self.textColor = [UIColor whiteColor];
        self.font = [UIFont boldSystemFontOfSize:12];
        self.textAlignment = NSTextAlignmentCenter;
        self.clipsToBounds = YES;
        self.hidden = YES;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    }
    return self;
}

- (void)setBadgeColor:(UIColor *)badgeColor {
    _badgeColor = badgeColor;
    self.backgroundColor = badgeColor;
}

- (void)setBadgeValue:(NSInteger)badgeValue {
    _badgeValue = badgeValue;
    if (badgeValue <= 0) {
        self.hidden = YES;
        self.text = nil;
        return;
    }
    self.hidden = NO;
    self.text = badgeValue > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)badgeValue];
    [self sizeToFit];
    CGFloat side = MAX(CGRectGetWidth(self.bounds) + 10, 18);
    self.bounds = CGRectMake(0, 0, side, 18);
    self.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2.0;
    [self layoutInSuperview];
}

- (void)setPosition:(SimpleBadgePosition)position {
    _position = position;
    [self layoutInSuperview];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self layoutInSuperview];
}

- (void)layoutInSuperview {
    if (!self.superview) {
        return;
    }
    CGFloat x = CGRectGetWidth(self.superview.bounds) - CGRectGetWidth(self.bounds) * 0.35;
    CGFloat y = -CGRectGetHeight(self.bounds) * 0.35;
    self.center = CGPointMake(x, y);
}

@end

@implementation UIView (SimpleBadge)

- (SimpleBadgeView *)badgeView {
    SimpleBadgeView *badgeView = objc_getAssociatedObject(self, kSimpleBadgeViewKey);
    if (!badgeView) {
        badgeView = [[SimpleBadgeView alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(self, kSimpleBadgeViewKey, badgeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self addSubview:badgeView];
    }
    return badgeView;
}

@end
