//
//  czzBigImageModeTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 27/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBigImageModeTableViewCell.h"

@interface czzBigImageModeTableViewCell()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigImageViewHeightConstraint;

@end

@implementation czzBigImageModeTableViewCell

- (void)renderContent {
    [super renderContent];
    NSString *imageName = self.thread.imgSrc.lastPathComponent;
    if (imageName.length && [[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
        UIImage *fullsizeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
        self.cellImageView.image = fullsizeImage;
    }
    UIImage *currentImage = self.cellImageView.image;
    if (currentImage && currentImage != self.placeholderImage) {
        CGFloat aspectRatio = currentImage.size.height / currentImage.size.width;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        CGFloat widthConstant = CGRectGetWidth(self.contentView.frame) - 16;
        CGFloat height = aspectRatio * widthConstant;
        // Limit the height.
        if (height > CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75) {
            height = CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75;
        }
        self.bigImageViewHeightConstraint.constant = height;
    } else {
        self.bigImageViewHeightConstraint.constant = 0;
    }
}


@end
