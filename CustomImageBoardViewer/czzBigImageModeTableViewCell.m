//
//  czzBigImageModeTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 27/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBigImageModeTableViewCell.h"

#import "czzImageDownloader.h"
#import <UIImageView+WebCache.h>

@interface czzBigImageModeTableViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *bigImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigImageViewHeightConstraint;
@property (strong, nonatomic) UITapGestureRecognizer *tapOnImageViewRecognizer;
@end

@implementation czzBigImageModeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tapOnImageViewRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(tapOnImageView:)];
    [self.bigImageView addGestureRecognizer:self.tapOnImageViewRecognizer];
}

- (void)renderContent {
    [super renderContent];
    NSString *imageName = self.thread.imgSrc.lastPathComponent;
    UIImage *fullSizeImage;
    if (self.allowImage && imageName.length && [[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
        fullSizeImage = [UIImage imageWithContentsOfFile:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName].path];
    }
    // Big image view would be only enabled for thread view cell.
    self.bigImageView.userInteractionEnabled = self.cellType == threadViewCellTypeThread;
    // Enlarge the UIImageView for full size images.
    if (fullSizeImage) {
        CGFloat aspectRatio = fullSizeImage.size.height / fullSizeImage.size.width;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        CGFloat widthConstant = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
        CGFloat height = aspectRatio * widthConstant;
        // Limit the height.
        if (height > CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75) {
            height = CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75;
        }
        self.bigImageViewHeightConstraint.constant = height;
        self.bigImageViewHeightConstraint.priority = 999;
        self.bigImageView.image = fullSizeImage;
        self.cellImageView.hidden = YES;
    } else {
        self.bigImageViewHeightConstraint.constant = 0;
        self.bigImageViewHeightConstraint.priority = 1;
        self.bigImageView.image = nil;
        self.cellImageView.hidden = NO;
    }
    [self setNeedsDisplay];
}

#pragma mark - czzImageDownloaderManagerDelegate

- (void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    [super imageDownloaderManager:manager
               downloadedFinished:downloader
                        imageName:imageName
                    wasSuccessful:success];
    if (success && !downloader.isThumbnail && [imageName isEqualToString:self.thread.imgSrc.lastPathComponent]) {
        self.bigImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
        [self.delegate threadViewCellContentChanged:self];
    }
}

@end
