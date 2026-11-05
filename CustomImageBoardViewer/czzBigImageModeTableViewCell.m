//
//  czzBigImageModeTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 27/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBigImageModeTableViewCell.h"

#import "czzImageDownloader.h"
#import "czzThreadViewCellHeaderView.h"
#import "czzThreadViewCellFooterView.h"
#import "czzNoSelectionTextView.h"

@interface czzBigImageModeTableViewCell()
@property (strong, nonatomic) UIImageView *bigImageView;
@property (strong, nonatomic) NSLayoutConstraint *bigImageViewHeightConstraint;
@property (strong, nonatomic) UILabel *bigImageGifLabel;
@property (strong, nonatomic) UITapGestureRecognizer *tapOnImageViewRecognizer;
@end

@implementation czzBigImageModeTableViewCell

/// Layout constants carried over from the retired czzBigImageModeTableViewCell nib.
static CGFloat const kBigImageInset = 8;
static CGFloat const kBigImageAccessoryInset = 20;
static CGFloat const kBigImageHeaderInset = 4;
static CGFloat const kBigImageSectionSpacing = 8;
static CGFloat const kBigImageSeparatorHeight = 2;
static CGFloat const kBigImageDefaultHeight = 130;

+ (instancetype)threadCell {
    return [[self alloc] initWithStyle:UITableViewCellStyleDefault
                       reuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
}

/// Lays the cell out full width: header, text, one edge-to-edge image, footer.
- (void)buildViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    UIView *contentView = self.contentView;
    contentView.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1];

    czzThreadViewCellHeaderView *cellHeaderView = [[czzThreadViewCellHeaderView alloc] init];
    cellHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:cellHeaderView];
    self.cellHeaderView = cellHeaderView;

    UITextView *contentLabel = [[czzNoSelectionTextView alloc] init];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:contentLabel];
    self.contentLabel = contentLabel;

    // Thumbnail shown while the full size image has not been cached yet.
    UIImageView *cellImageView = [[UIImageView alloc] init];
    cellImageView.translatesAutoresizingMaskIntoConstraints = NO;
    cellImageView.contentMode = UIViewContentModeScaleAspectFit;
    [contentView addSubview:cellImageView];
    self.cellImageView = cellImageView;

    UIView *imageContainer = [[UIView alloc] init];
    imageContainer.translatesAutoresizingMaskIntoConstraints = NO;
    imageContainer.clipsToBounds = YES;
    [contentView addSubview:imageContainer];

    UIImageView *bigImageView = [[UIImageView alloc] init];
    bigImageView.translatesAutoresizingMaskIntoConstraints = NO;
    bigImageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageContainer addSubview:bigImageView];
    self.bigImageView = bigImageView;

    UILabel *bigImageGifLabel = [[UILabel alloc] init];
    bigImageGifLabel.translatesAutoresizingMaskIntoConstraints = NO;
    bigImageGifLabel.text = @"GIF";
    bigImageGifLabel.font = [UIFont boldSystemFontOfSize:10];
    bigImageGifLabel.textColor = [UIColor colorWithRed:0.714 green:0.306 blue:0.016 alpha:1];
    bigImageGifLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    bigImageGifLabel.hidden = YES;
    [imageContainer addSubview:bigImageGifLabel];
    self.bigImageGifLabel = bigImageGifLabel;

    czzThreadViewCellFooterView *cellFooterView = [[czzThreadViewCellFooterView alloc] init];
    cellFooterView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:cellFooterView];
    self.cellFooterView = cellFooterView;

    UIView *bottomSeparator = [[UIView alloc] init];
    bottomSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    bottomSeparator.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [contentView addSubview:bottomSeparator];

    CGFloat imageHeight = kBigImageDefaultHeight;
    NSLayoutConstraint *bigImageHeight = [bigImageView.heightAnchor constraintEqualToConstant:imageHeight];
    // renderContent drives the real height; this keeps layout valid beforehand.
    bigImageHeight.priority = 250;
    bigImageHeight.active = YES;
    self.bigImageViewHeightConstraint = bigImageHeight;

    [NSLayoutConstraint activateConstraints:@[
        [cellHeaderView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [cellHeaderView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:kBigImageHeaderInset],
        [contentView.trailingAnchor constraintEqualToAnchor:cellHeaderView.trailingAnchor constant:kBigImageHeaderInset],

        [contentLabel.topAnchor constraintEqualToAnchor:cellHeaderView.bottomAnchor constant:kBigImageSectionSpacing],
        [contentLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:kBigImageInset],
        [contentView.trailingAnchor constraintEqualToAnchor:contentLabel.trailingAnchor constant:kBigImageInset],

        // The container owns the edge-to-edge width; the image fills it.
        [imageContainer.topAnchor constraintEqualToAnchor:contentLabel.bottomAnchor constant:kBigImageSectionSpacing],
        [imageContainer.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:imageContainer.trailingAnchor],

        [bigImageView.topAnchor constraintEqualToAnchor:imageContainer.topAnchor],
        [bigImageView.leadingAnchor constraintEqualToAnchor:imageContainer.leadingAnchor],
        [bigImageView.trailingAnchor constraintEqualToAnchor:imageContainer.trailingAnchor],
        [bigImageView.bottomAnchor constraintEqualToAnchor:imageContainer.bottomAnchor],

        [cellImageView.topAnchor constraintEqualToAnchor:imageContainer.topAnchor],
        [cellImageView.leadingAnchor constraintEqualToAnchor:imageContainer.leadingAnchor],
        [cellImageView.trailingAnchor constraintEqualToAnchor:imageContainer.trailingAnchor],
        [cellImageView.bottomAnchor constraintEqualToAnchor:imageContainer.bottomAnchor],

        [bigImageGifLabel.centerXAnchor constraintEqualToAnchor:bigImageView.centerXAnchor],
        [bigImageGifLabel.bottomAnchor constraintEqualToAnchor:bigImageView.bottomAnchor],

        [cellFooterView.topAnchor constraintEqualToAnchor:imageContainer.bottomAnchor constant:kBigImageSectionSpacing],
        [cellFooterView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:kBigImageAccessoryInset],
        [contentView.trailingAnchor constraintEqualToAnchor:cellFooterView.trailingAnchor constant:kBigImageAccessoryInset],

        [bottomSeparator.topAnchor constraintEqualToAnchor:cellFooterView.bottomAnchor],
        [bottomSeparator.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:kBigImageAccessoryInset],
        [contentView.trailingAnchor constraintEqualToAnchor:bottomSeparator.trailingAnchor],
        [bottomSeparator.heightAnchor constraintEqualToConstant:kBigImageSeparatorHeight],
        [contentView.bottomAnchor constraintEqualToAnchor:bottomSeparator.bottomAnchor]
    ]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self addBigImageTapRecognizer];
}

- (void)commonInit {
    [super commonInit];
    [self addBigImageTapRecognizer];
}

- (void)addBigImageTapRecognizer {
    if (self.tapOnImageViewRecognizer) { return; }
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
        CGFloat desiredHeight = 0;
        CGFloat aspectRatio = fullSizeImage.size.height / fullSizeImage.size.width;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        CGFloat widthConstant = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
        desiredHeight = aspectRatio * widthConstant;
        // Limit the height.
        if (desiredHeight > CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75) {
            desiredHeight = CGRectGetHeight([UIScreen mainScreen].bounds) * 0.75;
        }
        // If the calculated height is already bigger than the actual image height.
        if (desiredHeight > fullSizeImage.size.height) {
            desiredHeight = fullSizeImage.size.height;
        }
        self.bigImageViewHeightConstraint.constant = desiredHeight;
        self.bigImageViewHeightConstraint.priority = 999;
        self.bigImageView.image = fullSizeImage;
        self.cellImageView.hidden = YES;
        self.bigImageGifLabel.hidden = self.gifLabel.hidden;
    } else {
        self.bigImageViewHeightConstraint.constant = 0;
        self.bigImageViewHeightConstraint.priority = 1;
        self.bigImageView.image = nil;
        self.cellImageView.hidden = NO;
        self.bigImageGifLabel.hidden = YES;
    }
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (UIImage *)placeholderImage {
    return [UIImage imageNamed:@"Icon.png"];
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
