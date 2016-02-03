//
//  czzBannerView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBannerView.h"

@interface czzBannerView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation czzBannerView

- (void)layoutSubviews {
    self.titleLabel.text = self.title;
    self.cancelButton.hidden = !self.allowCancel;
    [super layoutSubviews];
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    if (self.title.length) {
        // Has content, calculate its height.
        CGRect titleRect = [self.title boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.titleLabel.frame), MAXFLOAT)
                                                    options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName: self.titleLabel.font}
                                                    context:nil];
        intrinsicContentSize.height = CGRectGetHeight(titleRect);
        // Should not be bigger than 120, or smaller than 40;
        if (intrinsicContentSize.height >= 120) {
            intrinsicContentSize.height = 120;
        } else if (intrinsicContentSize.height <= 40) {
            intrinsicContentSize.height = 40;
        }
    } else {
        // No content, make it 40.
        intrinsicContentSize.height = 40;
    }
    DLog(@"content size: %@", [NSValue valueWithCGSize:intrinsicContentSize]);
    return intrinsicContentSize;
}

#pragma mark - UIActions.

- (IBAction)cancelButtonAction:(id)sender {
    DLog(@"");
    if ([self.delegate respondsToSelector:@selector(bannerView:didTouchButton:)]) {
        [self.delegate bannerView:self
                   didTouchButton:sender];
    }
}

- (IBAction)tapOnBannerViewAction:(id)sender {
    DLog(@"");
    if ([self.delegate respondsToSelector:@selector(bannerViewDidTouch:)]) {
        [self.delegate bannerViewDidTouch:sender];
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
    }
}

@end
