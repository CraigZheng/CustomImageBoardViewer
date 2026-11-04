//
//  czzBannerView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBannerView.h"

@interface czzBannerView()
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *cancelButton;
@end

@implementation czzBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:161.0/255.0 blue:71.0/255.0 alpha:1.0];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.font = [UIFont systemFontOfSize:15];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.titleLabel];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *cancelButtonImage = [[UIImage imageNamed:@"delete.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.cancelButton setImage:cancelButtonImage forState:UIControlStateNormal];
    self.cancelButton.tintColor = [UIColor whiteColor];
    [self.cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.cancelButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:40],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-40],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.cancelButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-13],
        [self.cancelButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.cancelButton.widthAnchor constraintEqualToConstant:40],
        [self.cancelButton.heightAnchor constraintEqualToConstant:40]
    ]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBannerViewAction:)];
    [self addGestureRecognizer:tap];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.text = self.title;
    self.cancelButton.hidden = !self.allowCancel;
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    if (self.title.length) {
        CGRect titleRect = [self.title boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds) - 80, MAXFLOAT)
                                                    options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName: self.titleLabel.font}
                                                    context:nil];
        intrinsicContentSize.height = CGRectGetHeight(titleRect);
        if (intrinsicContentSize.height >= 120) {
            intrinsicContentSize.height = 120;
        } else if (intrinsicContentSize.height <= 40) {
            intrinsicContentSize.height = 40;
        }
    } else {
        intrinsicContentSize.height = 40;
    }
    return intrinsicContentSize;
}

#pragma mark - UIActions.

- (void)cancelButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(bannerView:didTouchButton:)]) {
        [self.delegate bannerView:self didTouchButton:sender];
    }
}

- (void)tapOnBannerViewAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(bannerViewDidTouch:)]) {
        [self.delegate bannerViewDidTouch:self];
    }
}

#pragma mark - Setters

- (void)setAllowCancel:(BOOL)allowCancel {
    if (_allowCancel != allowCancel) {
        _allowCancel = allowCancel;
        [self setNeedsLayout];
    }
}

- (void)setTitle:(NSString *)title {
    if (![title isEqualToString:_title]) {
        _title = title;
        [self setNeedsLayout];
        [self invalidateIntrinsicContentSize];
    }
}

@end
