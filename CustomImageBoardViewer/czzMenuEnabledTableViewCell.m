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
#import "czzThreadViewCellHeaderView.h"
#import "czzThreadViewCellFooterView.h"
#import "PureLayout/PureLayout.h"
#import "CustomImageBoardViewer-Swift.h"

#import <QuartzCore/QuartzCore.h>

static NSString * const kQuotedContent = @"quoted://";
NSInteger kCellImageViewHeight = 120;

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellImageViewButtonMinimumWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *cellImageViewButton;
@property (weak, nonatomic) IBOutlet UILabel *gifLabel;
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSMutableArray<czzThreadRefButton *> *referenceButtons;
@property (readonly, nonatomic) NSAttributedString *threadContent;
@property (strong, nonatomic) UIActionSheet *contentCopyActionSheet;
@property (strong, nonatomic) UIActionSheet *openLinkActionSheet;
@end

@implementation czzMenuEnabledTableViewCell

-(void)awakeFromNib {
    [super awakeFromNib];
    self.thumbnailFolder = [czzAppDelegate thumbnailFolder];
    self.imageFolder = [czzAppDelegate imageFolder];
    self.referenceButtons = [NSMutableArray new];
    self.shouldBlock = NO;
    self.allowImage = YES;
    self.shouldAllowClickOnImage = YES;
    self.contentLabel.delegate = self;
    // Add tap getsture recognizer to the image.
    // Add self to be a delegate of czzImageDownloaderManager.
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if (action == @selector(menuActionOpen:) && self.links.count > 0)
        return YES;
    return (action == @selector(menuActionReply:)
            || action == @selector(menuActionCopy:)
            // Delegate has to be responsiding this selector.
            || (action == @selector(menuActionTemporarilyHighlight:) && [self.delegate respondsToSelector:@selector(userWantsToTemporarilyHighlightUser:)])
            || action == @selector(menuActionHighlight:)
            || action == @selector(menuActionSearch:)
            || action == @selector(menuActionBlock:)
            || action == @selector(menuActionReport:));
}

-(BOOL)canBecomeFirstResponder{
    return YES;
}

- (void)prepareForReuse {
    // Reset all colours for header view, footer view, middle container view and content text view.
    self.contentView.backgroundColor = self.cellFooterView.backgroundColor
    = self.cellHeaderView.backgroundColor
    = self.contentLabel.backgroundColor
    = self.shouldTemporarilyHighlight ? [UIColor groupTableViewBackgroundColor] : [settingCentre viewBackgroundColour];
}

#pragma mark - custom menu action
-(void)menuActionCopy:(id)sender{
    self.contentCopyActionSheet = [[UIActionSheet alloc] initWithTitle: @"复制..."
                                                              delegate: self
                                                     cancelButtonTitle: nil
                                                destructiveButtonTitle: nil
                                                     otherButtonTitles: nil];
    [self.contentCopyActionSheet addButtonWithTitle:@"内容"];
    [self.contentCopyActionSheet addButtonWithTitle:@"串号"];
    [self.contentCopyActionSheet addButtonWithTitle:@"用户饼干"];
    [self.contentCopyActionSheet addButtonWithTitle:@"取消"];
    self.contentCopyActionSheet.cancelButtonIndex = 3;
    [self.contentCopyActionSheet showInView:[UIApplication topViewController].view];
}

-(void)menuActionReply:(id)sender{
    if ([self.delegate respondsToSelector:@selector(userWantsToReply:inParentThread:)]) {
        [self.delegate userWantsToReply:self.thread inParentThread:self.parentThread ? self.parentThread : self.thread];
    }
}

-(void)menuActionOpen:(id)sender{
    self.openLinkActionSheet = [[UIActionSheet alloc] initWithTitle: @"打开链接"
                                                           delegate: self
                                                  cancelButtonTitle: nil
                                             destructiveButtonTitle: nil
                                                  otherButtonTitles: nil];
    for (NSString *link in self.links) {
        [self.openLinkActionSheet addButtonWithTitle:link];
    }
    [self.openLinkActionSheet addButtonWithTitle:@"取消"];
    self.openLinkActionSheet.cancelButtonIndex = self.links.count;
    
    [self.openLinkActionSheet showInView:[UIApplication topViewController].view];
}

- (void)menuActionReport:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToReport:inParentThread:)]) {
        [self.delegate userWantsToReport:self.thread inParentThread:self.parentThread ? self.parentThread : self.thread];
    }
}

- (void)menuActionTemporarilyHighlight:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToTemporarilyHighlightUser:)]) {
        [self.delegate userWantsToTemporarilyHighlightUser:self.thread.UID];
    }
}

-(void)menuActionHighlight:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToHighlightUser:)]) {
        [self.delegate userWantsToHighlightUser:self.thread.UID];
    }
}

- (void)menuActionBlock:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userWantsToBlockUser:)]) {
        [self.delegate userWantsToBlockUser:self.thread.UID];
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
    if (self.shouldBlock) {
        self.contentLabel.text = [[NSAttributedString alloc] initWithString:@" - - - 屏蔽 - - - "
                                                                              attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    } else {
        NSMutableAttributedString *contentAttrString = [self.threadContent mutableCopy];
        [contentAttrString addAttribute:NSFontAttributeName value:settingCentre.contentFont range:NSMakeRange(0, contentAttrString.length)];
        if (self.nightyMode) {
            // If nighty mode, add nighty mode attributes to the text.
            [contentAttrString addAttribute:NSForegroundColorAttributeName
                                      value:settingCentre.contentTextColour
                                      range:NSMakeRange(0, contentAttrString.length)];
            self.contentLabel.text = contentAttrString;
        }
        // For quoted contents, made the responding text clickable.
        for (NSNumber *quotedNumber in self.thread.replyToList) {
            for (NSValue *rangeValue in [contentAttrString.string rangesOf:quotedNumber.stringValue]) {
                [contentAttrString addAttributes:@{NSLinkAttributeName:[NSString stringWithFormat:@"%@%@", kQuotedContent, quotedNumber.stringValue]}
                                           range:rangeValue.rangeValue];
            }
        }
        self.contentLabel.text = contentAttrString;
    }
    // Images.
    UIImage *previewImage;
    NSString *imageName;
    if (self.allowImage && (imageName = self.thread.imgSrc.lastPathComponent).length) {
        previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
        self.cellImageView.image = previewImage ?: self.placeholderImage;
        self.cellImageViewHeightConstraint.constant = kCellImageViewHeight;
        self.cellImageViewButtonMinimumWidthConstraint.active = YES;
        self.gifLabel.hidden = ![imageName.pathExtension.lowercaseString isEqualToString:@"gif"];
    } else {
        // Completely invisible.
        self.cellImageView.image = nil;
        self.cellImageViewHeightConstraint.constant = 0;
        self.cellImageViewButtonMinimumWidthConstraint.active = NO;
        self.gifLabel.hidden = YES;
    }
    [self setNeedsUpdateConstraints];
    // Header and footer.
    self.cellHeaderView.highlightColour = self.highlightColour;
    self.cellHeaderView.nickname = self.nickname;
    self.cellHeaderView.parentUID = self.parentThread.UID;
    self.cellFooterView.thread = self.cellHeaderView.thread = self.thread;
}

#pragma mark - UI actions
- (IBAction)tapOnImageView:(id)sender {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.shouldAllowClickOnImage && [self.delegate respondsToSelector:@selector(userTapInImageView:)]) {
        [self.delegate userTapInImageView:self];
    } else {
        DDLogDebug(@"Tap on image view not allow.");
    }
}

- (void)showThreadWithID:(NSString *)threadID {
    if ([self.delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
        [self.delegate userTapInQuotedText:threadID];
    }
}

- (void)userTapInRefButton:(id)sender {
    if ([sender isKindOfClass:[czzThreadRefButton class]]) {
        [self showThreadWithID:[NSString stringWithFormat:@"%ld", (long)[(czzThreadRefButton *)sender threadRefNumber]]];
    }
}

#pragma - mark UIActionSheet delegate
//Open the link associated with the button
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (actionSheet == self.openLinkActionSheet && buttonTitle.length) {
        NSString *hostPrefix = [settingCentre a_isle_host];
        if (hostPrefix.length && [buttonTitle rangeOfString:hostPrefix options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if ([self.delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
                [self.delegate userTapInQuotedText:[buttonTitle stringByReplacingOccurrencesOfString:hostPrefix withString:@""]];
            }
            return;
        }
        
        NSURL *link = [NSURL URLWithString:buttonTitle];
        [[UIApplication sharedApplication] openURL:link];
    } else if (actionSheet == self.contentCopyActionSheet && buttonTitle.length) {
        NSString *copyContent = @"";
        if ([buttonTitle isEqualToString:@"内容"]) {
            NSString *sharingContent = self.thread.content.string;
            NSString *threadLink = [[settingCentre share_post_url] stringByReplacingOccurrencesOfString:kThreadID
                                                                                             withString:[NSString stringWithFormat:@"%ld", (long)[(self.parentThread ? self.parentThread : self.thread) ID]]];
            copyContent = [NSString stringWithFormat:@"%@\n\n%@", sharingContent, threadLink];
        } else if ([buttonTitle isEqualToString:@"串号"]) {
            copyContent = [NSString stringWithFormat:@"No.%ld", (long)self.thread.ID];
        } else if ([buttonTitle isEqualToString:@"用户饼干"]) {
            copyContent = self.thread.UID;
        }
        if (copyContent.length) {
            [[UIPasteboard generalPasteboard] setString:copyContent];
            [AppDelegate showToast:[NSString stringWithFormat:@"%@ 已复制", buttonTitle]];
        }
    }
}

#pragma mark - Setters

-(void)setThread:(czzThread *)thread{
    if (_thread != thread) {
        _thread = thread;
        if (thread.content) {
            NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
            self.links = [NSMutableArray new];
            NSArray *matches = [linkDetector matchesInString:self.threadContent.string
                                                     options:0
                                                       range:NSMakeRange(0, [self.threadContent.string length])];
            for (NSTextCheckingResult *match in matches) {
                if ([match resultType] == NSTextCheckingTypeLink) {
                    NSURL *url = [match URL];
                    [self.links addObject:url.absoluteString];
                }
            }
        }
    }
}

#pragma mark - Getters

- (NSAttributedString *)threadContent {
    NSAttributedString *threadContent;
    // When the cell is displaying in home view controller, and the content is very long.
    if (settingCentre.userDefShouldCollapseLongContent
        && self.cellType == threadViewCellTypeHome
        && self.thread.content.length > settingCentre.long_thread_threshold) {
        NSMutableAttributedString *tempThreadContent = [[self.thread.content attributedSubstringFromRange:NSMakeRange(0, settingCentre.long_thread_threshold)] mutableCopy];
        [tempThreadContent appendAttributedString:[[NSAttributedString alloc] initWithString:@"..."
                                                                                  attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}]];
        threadContent = tempThreadContent;
    } else {
        threadContent = self.thread.content;
    }
    return threadContent;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateFormat:@"yyyy MM-dd, HH:mm"];
    }
    
    return _dateFormatter;
}

- (UIImage *)placeholderImage {
    return [UIImage imageNamed:@"iTunesArtwork.png"];
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

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)URL {
    if ([URL.absoluteString hasPrefix:kQuotedContent] && URL.absoluteString.numericString.integerValue > 0) {
        [self showThreadWithID:URL.absoluteString.numericString];
    } else if ([URL.absoluteString containsString:[settingCentre a_isle_host]]) {
        NSString *lastComponent = [URL.absoluteString componentsSeparatedByString:@"/"].lastObject;
        if (lastComponent.integerValue > 0) {
            [self showThreadWithID:lastComponent];
        }
    } else if ([URL.scheme isEqualToString:@"applewebdata"]) {
        // Foe applewebdata bullshit.
        // Strip out applewebdata://<UUID> prefix applied when HTML is loaded locally
        NSString *requestURLString = URL.absoluteString;
        NSString *trimmedRequestURLString = [requestURLString stringByReplacingOccurrencesOfString:@"^(?:applewebdata://[0-9A-Z-]*/?)" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, requestURLString.length)].stringByRemovingPercentEncoding;
        // Find the links from this script.
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:trimmedRequestURLString
                                                 options:0
                                                   range:NSMakeRange(0, [trimmedRequestURLString length])];
        for (NSTextCheckingResult *match in matches) {
            if ([match resultType] == NSTextCheckingTypeLink) {
                [UIApplication.sharedApplication openURL:match.URL];
            }
        }
    } else {
        if ([UIApplication.sharedApplication canOpenURL:URL]) {
            [UIApplication.sharedApplication openURL:URL];
        }
    }
}

#pragma mark - UIResponder methods.

- (BOOL)resignFirstResponder {
    // Resign contentLabel, the primary responder.
    [self.contentLabel resignFirstResponder];
    return [super resignFirstResponder];
}

@end
