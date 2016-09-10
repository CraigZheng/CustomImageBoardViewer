//
//  czzBigImageModeTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 27/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBigImageModeTableViewCell.h"

#import "czzImageDownloader.h"

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
    // If big image view does not have a gesture recognizer.
    self.bigImageView.gestureRecognizers = @[self.tapOnImageViewRecognizer];
    NSString *imageName = self.thread.imgSrc.lastPathComponent;
    if (self.allowImage && imageName.length && [[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
        UIImage *fullsizeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
        self.bigImageView.image = fullsizeImage;
        self.cellImageView.hidden = YES;
    } else {
        self.bigImageView.image = nil;
        self.cellImageView.hidden = NO;
    }
    // Enlarge the UIImageView for full size images.
    if (self.bigImageView.image) {
        // self.bigImageViewHeightConstraint is a lesser equal relationship.
        self.bigImageViewHeightConstraint.constant = CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75;
        self.bigImageViewHeightConstraint.priority = 999;
    } else {
        self.bigImageViewHeightConstraint.constant = 0;
        self.bigImageViewHeightConstraint.priority = 1;
    }
    [self setNeedsLayout];
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
