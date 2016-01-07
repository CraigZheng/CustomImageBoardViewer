//
//  czzMenuEnabledTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****\n\n"


#import "czzMenuEnabledTableViewCell.h"
#import "czzAppDelegate.h"
#import "czzImageCacheManager.h"
#import "czzThreadRefButton.h"
#import "czzSettingsCentre.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzThreadViewCellHeaderView.h"
#import "czzThreadViewCellFooterView.h"
#import "PureLayout/PureLayout.h"

#import <QuartzCore/QuartzCore.h>

static NSInteger const fixedConstraintConstant = 120;

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate, czzImageDownloaderManagerDelegate>
@property (weak, nonatomic) IBOutlet czzThreadViewCellHeaderView *cellHeaderView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellFooterView *cellFooterView;
@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewLeadingConstraint;

@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIImage *placeholderImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapOnImageViewRecognizer;

@property (strong, nonatomic) NSLayoutConstraint *imageViewCentreHorizontalConstraint;
@property (strong, nonatomic) NSLayoutConstraint *fixedImageViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *fixedImageViewWidthConstraint;
@property (strong, nonatomic) NSLayoutConstraint *flexibleImageViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *flexibleImageViewWidthConstraint;

@end

@implementation czzMenuEnabledTableViewCell

-(void)awakeFromNib {
    self.thumbnailFolder = [czzAppDelegate thumbnailFolder];
    self.imageFolder = [czzAppDelegate imageFolder];
    self.shouldHighlight = YES;
    self.allowImage = YES;
    self.shouldAllowClickOnImage = YES;

    [self.cellImageView addGestureRecognizer:self.tapOnImageViewRecognizer];
    // Make sure the height of the image view never exceed the width.
    [self.cellImageView autoMatchDimension:ALDimensionHeight
                                     toDimension:ALDimensionWidth
                                          ofView:self.cellImageView
                                  withMultiplier:1.0
                                        relation:NSLayoutRelationLessThanOrEqual];
    // Add the fixed constraitns, constants = 120, priorities = high.
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        self.fixedImageViewHeightConstraint = [self.cellImageView autoSetDimension:ALDimensionHeight
                                                                            toSize:fixedConstraintConstant];
        self.fixedImageViewWidthConstraint = [self.cellImageView autoSetDimension:ALDimensionWidth
                                                                           toSize:fixedConstraintConstant];
    }];
    // Add the flexible constraints, constants = 1, priorities = 1.
    [NSLayoutConstraint autoSetPriority:1 forConstraints:^{
        self.flexibleImageViewHeightConstraint = [self.cellImageView autoSetDimension:ALDimensionHeight
                                                                               toSize:1];
        self.flexibleImageViewWidthConstraint = [self.cellImageView autoSetDimension:ALDimensionWidth
                                                                              toSize:1];
    }];
    
    // Apply shadow and radius to background view.
    self.threadContentView.layer.masksToBounds = NO;
    self.threadContentView.layer.cornerRadius = 5;

    // Add self to be a delegate of czzImageDownloaderManager.
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if (action == @selector(menuActionOpen:) && self.links.count > 0)
        return YES;
    return (action == @selector(menuActionReply:) ||
            action == @selector(menuActionCopy:)
            || action == @selector(menuActionHighlight:)
            || action == @selector(menuActionSearch:));
}

-(BOOL)canBecomeFirstResponder{
    return YES;
}

-(void)resetViews {
    //colours
    if (self.nightyMode) {
        UIColor *viewBackgroundColour = [settingCentre viewBackgroundColour];
        self.contentTextView.backgroundColor = viewBackgroundColour;
        self.threadContentView.backgroundColor = viewBackgroundColour;
        self.contentView.backgroundColor = [UIColor darkGrayColor];
    } else {
        self.contentTextView.backgroundColor = [UIColor whiteColor];
        self.threadContentView.backgroundColor = [UIColor whiteColor];
        self.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }

}

#pragma mark - custom menu action
-(void)menuActionCopy:(id)sender{
    [[UIPasteboard generalPasteboard] setString:self.thread.content.string];
    [AppDelegate showToast:@"内容已复制"];
}

-(void)menuActionReply:(id)sender{
    if ([self.delegate respondsToSelector:@selector(userWantsToReply:inParentThread:)]) {
        [self.delegate userWantsToReply:self.thread inParentThread:self.parentThread];
    }
}

-(void)menuActionOpen:(id)sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: @"打开链接"
                                                       delegate: self
                                              cancelButtonTitle: nil
                                         destructiveButtonTitle: nil
                                              otherButtonTitles: nil];
    for (NSString *link in self.links) {
        [actionSheet addButtonWithTitle:link];
    }
    [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.cancelButtonIndex = self.links.count;
    
    [actionSheet showInView:self.superview];
}

-(void)menuActionHighlight:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToHighLight:)]) {
        [self.delegate userWantsToHighLight:self.thread];
    }
}

-(void)menuActionSearch:(id) sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToSearch:)]) {
        [self.delegate userWantsToSearch:self.thread];
    }
}

#pragma mark - consturct UI elements
-(void)renderContent {
    [self resetViews];
    if (self.nightyMode) {
        NSMutableAttributedString *contentAttrString = [self.thread.content mutableCopy];
        [contentAttrString addAttribute:NSForegroundColorAttributeName value:settingCentre.contentTextColour range:NSMakeRange(0, contentAttrString.length)];
        self.contentTextView.attributedText = contentAttrString;
    } else {
        self.contentTextView.attributedText = self.thread.content;
    }
    self.contentTextView.font = settingCentre.contentFont;
            
    // Highlight the selected user.
    if (self.selectedUserToHighlight && [self.thread.UID isEqualToString:self.selectedUserToHighlight]) {
        self.contentTextView.backgroundColor = self.contentView.backgroundColor;
    }
    // Images.
    UIImage *previewImage;
    NSString *imageName;
    // Reset the cell image view, deactivate all size constraints.
    self.cellImageView.image = nil;
    if (self.allowImage && (imageName = self.thread.imgSrc.lastPathComponent).length) {
        previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
        if (self.bigImageMode) {
            // If big image mode, try to grab the full size image.
            UIImage *fullImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
            previewImage = fullImage ?: previewImage;
        }
        self.cellImageView.image = previewImage ?: self.placeholderImage;
    }
    // If the image is not nil, reset the fixed constraints and calculate the flexible constraints.
    if (self.cellImageView.image) {
        self.fixedImageViewWidthConstraint.constant =
        self.fixedImageViewHeightConstraint.constant = fixedConstraintConstant;
        
        self.imageViewLeadingConstraint.constant = self.bigImageMode ? 8 : 16; // The leading would be 8 for big image mode.
        if (self.bigImageMode) {
            // Big image mode is on, calculate the aspect ratio and apply to the constraints.
            CGFloat aspectRatio = self.cellImageView.intrinsicContentSize.height / self.cellImageView.intrinsicContentSize.width;
            self.flexibleImageViewWidthConstraint.constant = CGRectGetWidth(self.frame) - self.imageViewLeadingConstraint.constant * 2; // Remove the padding for leading and trailing.
            self.flexibleImageViewHeightConstraint.constant = self.flexibleImageViewWidthConstraint.constant * aspectRatio;
        }
    } else {
        // Set all size constraints to 0 when nil.
        self.fixedImageViewWidthConstraint.constant =
        self.fixedImageViewHeightConstraint.constant =
        self.flexibleImageViewHeightConstraint.constant =
        self.flexibleImageViewWidthConstraint.constant = 0;
    }
    // Header and footer
    self.cellHeaderView.shouldHighLight = self.shouldHighlight;
    self.cellHeaderView.parentUID = self.parentThread.UID;
    self.cellFooterView.thread = self.cellHeaderView.thread = self.thread;

    [self.cellImageView layoutIfNeeded];
}

#pragma mark - UI actions
- (IBAction)tapOnImageView:(id)sender {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.shouldAllowClickOnImage && [self.delegate respondsToSelector:@selector(userTapInImageView:)]) {
        [self.delegate userTapInImageView:self.thread.imgSrc];
    } else {
        DDLogDebug(@"Tap on image view dis-allowed.");
    }
}

#pragma - mark UIActionSheet delegate
//Open the link associated with the button
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *hostPrefix = [settingCentre a_isle_host];
    if (hostPrefix.length && [buttonTitle rangeOfString:hostPrefix options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if ([self.delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
            [self.delegate userTapInQuotedText:[buttonTitle stringByReplacingOccurrencesOfString:hostPrefix withString:@""]];
        }
        return;
    }
    
    NSURL *link = [NSURL URLWithString:buttonTitle];
    [[UIApplication sharedApplication] openURL:link];
}

#pragma mark - Setters

-(void)setThread:(czzThread *)thread{
    _thread = thread;
    if (thread.content) {
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        self.links = [NSMutableArray new];
        NSArray *matches = [linkDetector matchesInString:_thread.content.string
                                                 options:0
                                                   range:NSMakeRange(0, [self.thread.content.string length])];
        for (NSTextCheckingResult *match in matches) {
            if ([match resultType] == NSTextCheckingTypeLink) {
                NSURL *url = [match URL];
                [self.links addObject:url.absoluteString];
            }
        }
    }
}

#pragma mark - Getters
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateFormat:@"yyyy MM-dd, HH:mm"];
    }
    
    return _dateFormatter;
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        _placeholderImage = [UIImage imageNamed:@"Icon.png"];
    }
    return _placeholderImage;
}

- (UITapGestureRecognizer *)tapOnImageViewRecognizer {
    if (!_tapOnImageViewRecognizer) {
        _tapOnImageViewRecognizer = [UITapGestureRecognizer new];
        [_tapOnImageViewRecognizer addTarget:self action:@selector(tapOnImageView:)];
    }
    return _tapOnImageViewRecognizer;
}

- (NSLayoutConstraint *)imageViewCentreHorizontalConstraint {
    if (!_imageViewCentreHorizontalConstraint) {
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired - 1 forConstraints:^{
            _imageViewCentreHorizontalConstraint = [self.cellImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        }];
    }
    return _imageViewCentreHorizontalConstraint;
}

- (void)setBigImageMode:(BOOL)bigImageMode {
    if (_bigImageMode != bigImageMode) {
        _bigImageMode = bigImageMode;
        if (bigImageMode) {
            // If big image mode, set priorities to 999.
            self.imageViewCentreHorizontalConstraint.priority =
            self.flexibleImageViewHeightConstraint.priority =
            self.flexibleImageViewWidthConstraint.priority = UILayoutPriorityRequired - 1;
        } else {
            self.imageViewCentreHorizontalConstraint.priority =
            self.flexibleImageViewHeightConstraint.priority =
            self.flexibleImageViewWidthConstraint.priority = 1;
        }
        [self renderContent];
        DDLogDebug(@"Toggle big image mode: %d", bigImageMode);
    }
}

- (void)setCellType:(threadViewCellType)cellType {
    if (_cellType != cellType) {
        _cellType = cellType;
        // When in big image mode, the cell image view should be disabled when the cell type is home.
        if (cellType == threadViewCellTypeHome && self.bigImageMode) {
            self.cellImageView.userInteractionEnabled = NO;
        } else {
            self.cellImageView.userInteractionEnabled = YES;
        }
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success && self.delegate) {
        if (downloader.isThumbnail) {
            if ([downloader.targetURLString.lastPathComponent isEqualToString:self.thread.imgSrc.lastPathComponent]) {
                self.cellImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:downloader.targetURLString.lastPathComponent]]];
                if (self.bigImageMode) {
                    if ([self.delegate respondsToSelector:@selector(threadViewCellContentChanged:)]) {
                        [self.delegate threadViewCellContentChanged:self];
                    }
                } else {
                    self.cellImageView.alpha = 0.5;
                    [UIView animateWithDuration:0.2 animations:^{
                        self.cellImageView.alpha = 1;
                    }];
                }
            }
        }
    }
}

@end
