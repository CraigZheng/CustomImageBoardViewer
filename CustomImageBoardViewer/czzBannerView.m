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

#pragma mark - Setters

- (void)setTitle:(NSString *)title {
    if (![title isEqualToString:_title]) {
        _title = title;
        [self setNeedsLayout];
    }
}

@end
