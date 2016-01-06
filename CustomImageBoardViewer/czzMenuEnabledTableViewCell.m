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
#import "czzSettingsCentre.h"
#import "czzThreadRefButton.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzThreadViewCellHeaderView.h"
#import "czzThreadViewCellFooterView.h"
#import "czzThreadCellImageView.h"

#import <QuartzCore/QuartzCore.h>

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate, czzImageDownloaderManagerDelegate, czzThreadCellImageViewDelegate>
@property (weak, nonatomic) IBOutlet czzThreadViewCellHeaderView *cellHeaderView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellFooterView *cellFooterView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *threadCellImageView;

@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property czzSettingsCentre *settingsCentre;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIImage *placeholderImage;
@end

@implementation czzMenuEnabledTableViewCell
@synthesize contentTextView;
@synthesize threadContentView;

@synthesize settingsCentre;
@synthesize myIndexPath;
@synthesize shouldHighlight;
@synthesize selectedUserToHighlight;
@synthesize links;
@synthesize parentThread;
@synthesize myThread;
@synthesize imageFolder;
@synthesize thumbnailFolder;
@synthesize delegate;

-(void)awakeFromNib {
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    imageFolder = [czzAppDelegate imageFolder];
    settingsCentre = [czzSettingsCentre sharedInstance];
    shouldHighlight = settingsCentre.userDefShouldHighlightPO;
//    self.threadCellImageView.delegate = self;
    self.shouldAllowClickOnImage = YES;
    
    // Apply shadow and radius to background view.
    threadContentView.layer.masksToBounds = NO;
    threadContentView.layer.cornerRadius = 5;

    // Add self to be a delegate of czzImageDownloaderManager.
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if (action == @selector(menuActionOpen:) && links.count > 0)
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
    if (settingsCentre.userDefNightyMode) {
        UIColor *viewBackgroundColour = [settingsCentre viewBackgroundColour];
        contentTextView.backgroundColor = viewBackgroundColour;
        threadContentView.backgroundColor = viewBackgroundColour;
        self.contentView.backgroundColor = [UIColor darkGrayColor];
    } else {
        contentTextView.backgroundColor = [UIColor whiteColor];
        threadContentView.backgroundColor = [UIColor whiteColor];
        self.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }

}

#pragma mark - custom menu action
-(void)menuActionCopy:(id)sender{
    [[UIPasteboard generalPasteboard] setString:self.myThread.content.string];
    [AppDelegate showToast:@"内容已复制"];
}

-(void)menuActionReply:(id)sender{
    if ([self.delegate respondsToSelector:@selector(userWantsToReply:inParentThread:)]) {
        [self.delegate userWantsToReply:self.myThread inParentThread:self.parentThread];
    }
}

-(void)menuActionOpen:(id)sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: @"打开链接"
                                                       delegate: self
                                              cancelButtonTitle: nil
                                         destructiveButtonTitle: nil
                                              otherButtonTitles: nil];
    for (NSString *link in links) {
        [actionSheet addButtonWithTitle:link];
    }
    [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.cancelButtonIndex = links.count;
    
    [actionSheet showInView:self.superview];
}

-(void)menuActionHighlight:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToHighLight:)]) {
        [self.delegate userWantsToHighLight:self.myThread];
    }
}

-(void)menuActionSearch:(id) sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToSearch:)]) {
        [self.delegate userWantsToSearch:self.myThread];
    }
}

#pragma mark - consturct UI elements
-(void)prepareUIWithMyThread {
    [self resetViews];
    if (myThread.imgSrc.length){
        // Has thumbnail image, show the preview image view...
        if ([settingsCentre userDefShouldUseBigImage]) {
            self.imageViewHeightConstraint.constant = 200;
        } else {
            self.imageViewHeightConstraint.constant = 100;
        }
        
        NSString *imageName = myThread.imgSrc.lastPathComponent;
        UIImage *previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];

        if (settingsCentre.userDefShouldUseBigImage)
        {
            if ([[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
                previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
            }
        }
        self.threadCellImageView.image = previewImage ?: self.placeholderImage;
    } else {
        self.imageViewHeightConstraint.constant = 1;
        self.threadCellImageView.image = nil;
    }
    //if harmful flag is set, display warning header of harmful thread
    NSMutableAttributedString *contentAttrString;
    if (myThread.content)
        contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:myThread.content];

    //content textview
    if (settingsCentre.userDefNightyMode)
        [contentAttrString addAttribute:NSForegroundColorAttributeName value:settingsCentre.contentTextColour range:NSMakeRange(0, contentAttrString.length)];

    contentTextView.attributedText = contentAttrString;
    contentTextView.font = settingsCentre.contentFont;
            
    //highlight the selected user
    if (selectedUserToHighlight && [myThread.UID isEqualToString:selectedUserToHighlight]) {
        contentTextView.backgroundColor = self.contentView.backgroundColor;
    }
    
    // Header and footer
    self.cellHeaderView.shouldHighLight = self.shouldHighlight;
    self.cellHeaderView.parentUID = self.parentThread.UID;
    self.cellFooterView.myThread = self.cellHeaderView.myThread = self.myThread;
//    // Big image mode?
//    self.threadCellImageView.bigImageMode = [settingsCentre userDefShouldUseBigImage];
//    if (self.threadCellImageView.bigImageMode && !self.shouldAllowClickOnImage) {
//        self.threadCellImageView.userInteractionEnabled = NO;
//    }
}

#pragma - mark UIActionSheet delegate
//Open the link associated with the button
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *hostPrefix = [settingCentre a_isle_host];
    if (hostPrefix.length && [buttonTitle rangeOfString:hostPrefix options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if ([delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
            [delegate userTapInQuotedText:[buttonTitle stringByReplacingOccurrencesOfString:hostPrefix withString:@""]];
        }
        return;
    }
    
    NSURL *link = [NSURL URLWithString:buttonTitle];
    [[UIApplication sharedApplication] openURL:link];
}

#pragma mark - user actions

-(void)userTapInImageView:(id)sender {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.shouldAllowClickOnImage && [delegate respondsToSelector:@selector(userTapInImageView:)]) {
        [delegate userTapInImageView:myThread.imgSrc];
    } else {
        DDLogDebug(@"Tap on image view dis-allowed.");
    }
}

#pragma mark - Setters

-(void)setMyThread:(czzThread *)thread{
    myThread = thread;
    if (myThread.content) {
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        links = [NSMutableArray new];
        NSArray *matches = [linkDetector matchesInString:myThread.content.string
                                                 options:0
                                                   range:NSMakeRange(0, [myThread.content.string length])];
        for (NSTextCheckingResult *match in matches) {
            if ([match resultType] == NSTextCheckingTypeLink) {
                NSURL *url = [match URL];
                [links addObject:url.absoluteString];
            }
        }
    }
    [self prepareUIWithMyThread];
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

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success && delegate) {
        if (downloader.isThumbnail) {
            if ([downloader.targetURLString.lastPathComponent isEqualToString:myThread.imgSrc.lastPathComponent]) {
                self.threadCellImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:downloader.targetURLString.lastPathComponent]]];
                if ([self.delegate respondsToSelector:@selector(threadViewCellContentChanged:)]) {
                    [self.delegate threadViewCellContentChanged:self];
                }
            }
        }
    }
}

#pragma mark - czzThreadCellImageViewDelegate

- (void)cellImageViewTapped:(czzThreadCellImageView *)imageView {
    if (self.shouldAllowClickOnImage && imageView.image) {
        [self userTapInImageView:nil];
    }
}

@end
