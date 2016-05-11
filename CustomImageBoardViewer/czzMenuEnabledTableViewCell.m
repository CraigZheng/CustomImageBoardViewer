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
//#import "PureLayout/PureLayout.h"

#import <QuartzCore/QuartzCore.h>

NSInteger const threadCellImageViewNormalHeight = 100;
static NSInteger const layoutConstraintZeroHeight = 0;
static NSInteger const footerViewNormalHeight = 20;
static NSString * const showThreadWithID = @"showThreadWithID";

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate, czzImageDownloaderManagerDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellHeaderView *cellHeaderView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellFooterView *cellFooterView;
@property (weak, nonatomic) IBOutlet UIView *contentContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (strong, nonatomic) UITapGestureRecognizer *tapOnImageViewRecognizer;
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIImage *placeholderImage;
@property (strong, nonatomic) NSMutableArray<czzThreadRefButton *> *referenceButtons;
@end

@implementation czzMenuEnabledTableViewCell

-(void)awakeFromNib {
    self.thumbnailFolder = [czzAppDelegate thumbnailFolder];
    self.imageFolder = [czzAppDelegate imageFolder];
    self.referenceButtons = [NSMutableArray new];
    self.shouldHighlight = YES;
    self.allowImage = YES;
    self.shouldAllowClickOnImage = YES;
    // Add tap getsture recognizer to the image.
    self.tapOnImageViewRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(tapOnImageView:)];
    [self.cellImageView addGestureRecognizer:self.tapOnImageViewRecognizer];
    // Add self to be a delegate of czzImageDownloaderManager.
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    for (czzThreadRefButton *button in self.referenceButtons) {
        [button removeFromSuperview];
    }
    // Clickable content, find the quoted text and add a button to corresponding location.
    if (self.thread.replyToList.count) {
        NSMutableAttributedString *mutableAttributedString = self.contentTextView.attributedText.mutableCopy;
        for (NSNumber *refNumber in self.thread.replyToList) {
            NSInteger rep = refNumber.integerValue;
            if (rep > 0) {
                NSString *quotedNumberText = [NSString stringWithFormat:@"%ld", (long)rep];
                NSRange range = [self.contentTextView.attributedText.string rangeOfString:quotedNumberText];
                if (range.location != NSNotFound){
                    [mutableAttributedString addAttribute:NSLinkAttributeName
                                                    value:[NSString stringWithFormat:@"showThreadWithID://%@", quotedNumberText]
                                                    range:range];
                }
            }
        }
        self.contentTextView.attributedText = mutableAttributedString;
    }
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

-(void)resetViewBackgroundColours {
    if (self.nightyMode) {
        self.contentView.backgroundColor = [UIColor darkGrayColor];
        
    } else {
        self.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    // Reset all colours for header view, footer view, middle container view and content text view.
    self.cellFooterView.backgroundColor = self.cellHeaderView.backgroundColor =
    self.contentContainerView.backgroundColor = self.contentTextView.backgroundColor =
    [settingCentre viewBackgroundColour];
}

- (void)highLight {
    self.contentTextView.backgroundColor = self.cellHeaderView.backgroundColor =
    self.cellFooterView.backgroundColor = self.contentContainerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
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

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

-(void)renderContent {
    [self resetViewBackgroundColours];
    if (self.nightyMode) {
        // If nighty mode, add nighty mode attributes to the text.
        NSMutableAttributedString *contentAttrString = [self.thread.content mutableCopy];
        [contentAttrString addAttribute:NSForegroundColorAttributeName
                                  value:settingCentre.contentTextColour
                                  range:NSMakeRange(0, contentAttrString.length)];
        self.contentTextView.attributedText = contentAttrString;
    } else {
        self.contentTextView.attributedText = self.thread.content;
    }
    self.contentTextView.font = settingCentre.contentFont;
    
    // Highlight the selected user.
    if (self.selectedUserToHighlight && [self.thread.UID isEqualToString:self.selectedUserToHighlight]) {
        [self highLight];
    }
    // Images.
    UIImage *previewImage;
    NSString *imageName;
    if (self.allowImage && (imageName = self.thread.imgSrc.lastPathComponent).length) {
        previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
        self.imageViewHeightConstraint.constant = threadCellImageViewNormalHeight;
        self.cellImageView.image = previewImage ?: self.placeholderImage;
    } else {
        // Completely invisible.
        self.imageViewHeightConstraint.constant = layoutConstraintZeroHeight;
        self.cellImageView.image = nil;
    }
    // Header and footer.
    self.cellHeaderView.shouldHighLight = self.shouldHighlight;
    self.cellHeaderView.parentUID = self.parentThread.UID;
    self.cellFooterView.thread = self.cellHeaderView.thread = self.thread;
    // Hide footer when its not necessary.
    if (self.cellFooterView.isHidden) {
        self.footerViewHeightConstraint.constant = layoutConstraintZeroHeight;
    } else {
        self.footerViewHeightConstraint.constant = footerViewNormalHeight;
    }
}

#pragma mark - UI actions
- (void)tapOnImageView:(id)sender {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.shouldAllowClickOnImage && [self.delegate respondsToSelector:@selector(userTapInImageView:)]) {
        [self.delegate userTapInImageView:self.thread.imgSrc];
    } else {
        DDLogDebug(@"Tap on image view not allow.");
    }
}

- (void)showThreadWithID:(NSString *)threadID {
    if ([self.delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
        [self.delegate userTapInQuotedText:threadID];
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
    if (_thread != thread) {
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
}

- (void)setCellType:(threadViewCellType)cellType {
    _cellType = cellType;
    if (cellType == threadViewCellTypeHome) {
        // When in Home view, disable all the fancy interaction with the contentTextView.
        self.contentTextView.userInteractionEnabled = NO;
        // When in big image mode, the cell image view should be disabled when the cell type is home.
        if (self.bigImageMode) {
            self.cellImageView.userInteractionEnabled = NO;
        }
    } else {
        self.contentTextView.userInteractionEnabled = self.cellImageView.userInteractionEnabled = YES;
    }
}

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
    if (success &&
        [self.delegate respondsToSelector:@selector(threadViewCellContentChanged:)]) {
        if ([downloader.targetURLString.lastPathComponent isEqualToString:self.thread.imgSrc.lastPathComponent]) {
            if (downloader.isThumbnail) {
                // Assign the thumbnail image.
                self.cellImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:downloader.targetURLString.lastPathComponent]]];
                self.cellImageView.alpha = 0.5;
                [UIView animateWithDuration:0.2 animations:^{
                    self.cellImageView.alpha = 1;
                }];
                [self.delegate threadViewCellContentChanged:self];
            }
        }
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    BOOL shouldInteract = YES;
    if ([URL.absoluteString hasPrefix:showThreadWithID]) {
        [self showThreadWithID:URL.absoluteString];
        shouldInteract = NO;
    }
    return shouldInteract;
}

#pragma mark - UIResponder methods.

- (BOOL)resignFirstResponder {
    // Resign contentTextView, the primary responder.
    [self.contentTextView resignFirstResponder];
    return [super resignFirstResponder];
}

@end
