//
//  czzRoundButton.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 23/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzRoundButton.h"

@interface czzRoundButton ()
@property (nonatomic, strong) UIView *circleBackgroundView;
@end

@implementation czzRoundButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // A bar button item's wrapper resizes the custom view, and it is not always square:
    // iOS 26 lays it out 36pt wide but only 26pt tall. Rounding the corners of that bounds
    // gives a capsule, so the circle is drawn as a separate square subview sized to the
    // shorter side instead.
    CGFloat side = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    self.circleBackgroundView.bounds = CGRectMake(0, 0, side, side);
    self.circleBackgroundView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.circleBackgroundView.layer.cornerRadius = side / 2;
    [self bringSubviewToFront:self.titleLabel];
}

- (void)commonInit {
    [self setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont systemFontOfSize:11];
    self.circleBackgroundView = [[UIView alloc] init];
    self.circleBackgroundView.userInteractionEnabled = NO;
    self.circleBackgroundView.backgroundColor = [UIColor whiteColor];
    [self insertSubview:self.circleBackgroundView atIndex:0];
}

@end
