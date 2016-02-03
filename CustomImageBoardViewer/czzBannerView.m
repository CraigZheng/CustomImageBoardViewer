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

@end

@implementation czzBannerView

- (void)layoutSubviews {
    self.titleLabel.text = self.title;
    [super layoutSubviews];
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    if (self.title.length) {
        // Has content, calculate its height.
        CGSize titleIntrinsicContentSize = self.titleLabel.intrinsicContentSize;
        intrinsicContentSize.height = titleIntrinsicContentSize.height;
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

#pragma mark - Setters

- (void)setTitle:(NSString *)title {
    if (![title isEqualToString:_title]) {
        _title = title;
        [self setNeedsLayout];
    }
}

@end
