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

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate, czzImageDownloaderManagerDelegate>
@property (weak, nonatomic) IBOutlet czzThreadViewCellHeaderView *cellHeaderView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellFooterView *cellFooterView;
@property (weak, nonatomic) IBOutlet UIImageView *threadCellImageView;

@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIImage *placeholderImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapOnImageViewRecognizer;
@property (weak, nonatomic) NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) NSLayoutConstraint *imageViewWidthConstraint;
@end

@implementation czzMenuEnabledTableViewCell

-(void)awakeFromNib {
    self.thumbnailFolder = [czzAppDelegate thumbnailFolder];
    self.imageFolder = [czzAppDelegate imageFolder];
    self.shouldHighlight = YES;
    self.allowImage = YES;
    [self.threadCellImageView addGestureRecognizer:self.tapOnImageViewRecognizer];
    self.shouldAllowClickOnImage = YES;
    
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
    UIImage *previewImage;
    if (self.thread.imgSrc.length && self.allowImage){
        NSString *imageName = self.thread.imgSrc.lastPathComponent;
        previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];

        if (self.bigImageMode)
        {
            if ([[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
                previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
            }
        }
        self.threadCellImageView.image = previewImage ?: self.placeholderImage;
    } else {
        self.threadCellImageView.image = nil;
    }
    
    NSMutableAttributedString *contentAttrString;
    if (self.thread.content)
        contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:self.thread.content];

    //content textview
    if (self.nightyMode)
        [contentAttrString addAttribute:NSForegroundColorAttributeName value:settingCentre.contentTextColour range:NSMakeRange(0, contentAttrString.length)];

    self.contentTextView.attributedText = contentAttrString;
    self.contentTextView.font = settingCentre.contentFont;
            
    //highlight the selected user
    if (self.selectedUserToHighlight && [self.thread.UID isEqualToString:self.selectedUserToHighlight]) {
        self.contentTextView.backgroundColor = self.contentView.backgroundColor;
    }
    
    // Header and footer
    self.cellHeaderView.shouldHighLight = self.shouldHighlight;
    self.cellHeaderView.parentUID = self.parentThread.UID;
    self.cellFooterView.thread = self.cellHeaderView.thread = self.thread;

    // If big image mode or no image at all, let the image view decide the rect.
    if (self.bigImageMode || !previewImage) {
        if (self.cellType
            == threadViewCellTypeThread) {
            self.threadCellImageView.userInteractionEnabled = YES;
        } else {
            self.threadCellImageView.userInteractionEnabled = NO;
        }
        self.imageViewWidthConstraint.priority = self.imageViewHeightConstraint.priority = 1;
    } else {
        self.threadCellImageView.userInteractionEnabled = YES;
        self.imageViewWidthConstraint.priority = self.imageViewHeightConstraint.priority = UILayoutPriorityRequired - 1;
    }
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

- (NSLayoutConstraint *)imageViewHeightConstraint {
    if (!_imageViewHeightConstraint ) {
        // Add the constraint programmatically
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired - 1 forConstraints:^{
            _imageViewHeightConstraint = [self.threadCellImageView autoSetDimension:ALDimensionHeight toSize:100];
        }];
    }
    return _imageViewHeightConstraint;
}

- (NSLayoutConstraint *)imageViewWidthConstraint {
    if (!_imageViewWidthConstraint ) {
        // Add the constraint programmatically
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired - 1 forConstraints:^{
            _imageViewWidthConstraint = [self.threadCellImageView autoSetDimension:ALDimensionWidth toSize:100];
        }];
    }
    return _imageViewWidthConstraint;
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success && self.delegate) {
        if (downloader.isThumbnail) {
            if ([downloader.targetURLString.lastPathComponent isEqualToString:self.thread.imgSrc.lastPathComponent]) {
                self.threadCellImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:downloader.targetURLString.lastPathComponent]]];
                if (self.bigImageMode && [self.delegate respondsToSelector:@selector(threadViewCellContentChanged:)]) {
                    [self.delegate threadViewCellContentChanged:self];
                }
            }
        }
    }
}

@end
