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

static NSInteger const fixedConstraintConstant = 100;
static NSInteger const veryHightConstraintPriority = 999;
static NSInteger const veryLowConstraintPriority = 1;

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate, czzImageDownloaderManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellHeaderView *cellHeaderView;
@property (weak, nonatomic) IBOutlet czzThreadViewCellFooterView *cellFooterView;
@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewCentreAlignConstraint;

@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIImage *placeholderImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapOnImageViewRecognizer;
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
    
    [self.cellImageView addGestureRecognizer:self.tapOnImageViewRecognizer];
    // Apply shadow and radius to background view.
    self.containerView.layer.masksToBounds = NO;
    self.containerView.layer.cornerRadius = 5;

    // Add self to be a delegate of czzImageDownloaderManager.
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    for (czzThreadRefButton *button in self.referenceButtons) {
        [button removeFromSuperview];
    }
    // Clickable content, find the quoted text and add a button to corresponding location.
    for (NSNumber *refNumber in self.thread.replyToList) {
        NSInteger rep = refNumber.integerValue;
        if (rep > 0) {
            NSString *quotedNumberText = [NSString stringWithFormat:@"%ld", (long)rep];
            NSRange range = [self.contentTextView.attributedText.string rangeOfString:quotedNumberText];
            if (range.location != NSNotFound){
                CGRect result = [self frameOfTextRange:range inTextView:self.contentTextView];
                
                if (!CGSizeEqualToSize(CGSizeZero, result.size)){
                    czzThreadRefButton *threadRefButton = [[czzThreadRefButton alloc] initWithFrame:CGRectMake(result.origin.x, result.origin.y + self.contentTextView.frame.origin.y, result.size.width, result.size.height)];
                    threadRefButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1f];
                    [threadRefButton addTarget:self action:@selector(userTapInRefButton:) forControlEvents:UIControlEventTouchUpInside];
                    threadRefButton.threadRefNumber = rep;
                    [self.contentView addSubview:threadRefButton];
                    [self.referenceButtons addObject:threadRefButton];
                }
            }
        }
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

-(void)resetViews {
    //colours
    if (self.nightyMode) {
        UIColor *viewBackgroundColour = [settingCentre viewBackgroundColour];
        self.contentTextView.backgroundColor = viewBackgroundColour;
        self.containerView.backgroundColor = viewBackgroundColour;
        self.contentView.backgroundColor = [UIColor darkGrayColor];
    } else {
        self.contentTextView.backgroundColor = [UIColor whiteColor];
        self.containerView.backgroundColor = [UIColor whiteColor];
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

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

-(void)renderContent {
    [self resetViews];
    if (self.nightyMode) {
        // If nighty mode, add nighty mode attributes to the text.
        NSMutableAttributedString *contentAttrString = [self.thread.content mutableCopy];
        [contentAttrString addAttribute:NSForegroundColorAttributeName value:settingCentre.contentTextColour range:NSMakeRange(0, contentAttrString.length)];
        self.contentTextView.attributedText = contentAttrString;
    } else {
        self.contentTextView.attributedText = self.thread.content;
    }
    self.contentTextView.font = settingCentre.contentFont;
    
    [self.contentTextView layoutIfNeeded];
    
    // Highlight the selected user.
    if (self.selectedUserToHighlight && [self.thread.UID isEqualToString:self.selectedUserToHighlight]) {
        self.contentTextView.backgroundColor = self.contentView.backgroundColor;
    }
    // Images.
    UIImage *previewImage;
    NSString *imageName;
    if (self.allowImage && (imageName = self.thread.imgSrc.lastPathComponent).length) {
        previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
        if (self.bigImageMode) {
            // If big image mode, try to grab the full size image.
            UIImage *fullImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
            previewImage = fullImage ?: previewImage;
        }
        self.imageViewHeightConstraint.constant =
        self.imageViewWidthConstraint.constant = fixedConstraintConstant;
        self.cellImageView.image = previewImage ?: self.placeholderImage;
    } else {
        // Reset the cell image view, deactivate all size constraints.
        self.imageViewHeightConstraint.constant =
        self.imageViewWidthConstraint.constant = 0;
        self.cellImageView.image = nil;
    }
    // If big image mode and have a valid image, calculate the aspect ratio.
    if (self.bigImageMode &&
        self.cellImageView.image &&
        self.cellImageView.image != self.placeholderImage) {
        CGFloat aspectRatio = self.cellImageView.intrinsicContentSize.height / self.cellImageView.intrinsicContentSize.width;
        self.imageViewWidthConstraint.constant = CGRectGetWidth(self.frame) - 8 * 2; // Remove the padding for leading and trailing.
        self.imageViewHeightConstraint.constant = self.imageViewWidthConstraint.constant * aspectRatio;
        // Positioning of the image view.
        self.imageViewCentreAlignConstraint.priority = veryHightConstraintPriority;
        // Make sure the height never bigger than 80% of width.
        if (self.imageViewHeightConstraint.constant > self.imageViewWidthConstraint.constant * 0.8) {
            self.imageViewHeightConstraint.constant = self.imageViewWidthConstraint.constant * 0.8;
        }
    } else {
        self.imageViewCentreAlignConstraint.priority = veryLowConstraintPriority;
    }
    
    // Header and footer
    self.cellHeaderView.shouldHighLight = self.shouldHighlight;
    self.cellHeaderView.parentUID = self.parentThread.UID;
    self.cellFooterView.thread = self.cellHeaderView.thread = self.thread;
    if (self.cellFooterView.isHidden) {
        self.footerContainerViewHeightConstraint.constant = 8;
    } else {
        self.footerContainerViewHeightConstraint.constant = 20;
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

- (void)userTapInRefButton:(id)sender {
    if ([sender isKindOfClass:[czzThreadRefButton class]]) {
        if ([self.delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
            [self.delegate userTapInQuotedText:[NSString stringWithFormat:@"%ld", (long)[(czzThreadRefButton *)sender threadRefNumber]]];
        }
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

- (void)setCellType:(threadViewCellType)cellType {
    _cellType = cellType;
    // When in big image mode, the cell image view should be disabled when the cell type is home.
    if (cellType == threadViewCellTypeHome && self.bigImageMode) {
        self.cellImageView.userInteractionEnabled = NO;
    } else {
        self.cellImageView.userInteractionEnabled = YES;
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success &&
        [self.delegate respondsToSelector:@selector(threadViewCellContentChanged:)]) {
        if ([downloader.targetURLString.lastPathComponent isEqualToString:self.thread.imgSrc.lastPathComponent]) {
            DDLogDebug(@"Content changed in %ld row, %p: %@ is downloaded.", (long)self.myIndexPath.row, self, downloader.targetURLString.lastPathComponent);
            if (downloader.isThumbnail) {
                // Assign the thumbnail image.
                self.cellImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:downloader.targetURLString.lastPathComponent]]];
                self.cellImageView.alpha = 0.5;
                [UIView animateWithDuration:0.2 animations:^{
                    self.cellImageView.alpha = 1;
                }];
                [self.delegate threadViewCellContentChanged:self];
                
            } else if (self.bigImageMode) {
                // Not thumbnail, but big image mode should inform delegate about the full size image as well.
                // If match, inform delegate.
                [self.delegate threadViewCellContentChanged:self];
            }
        }
    }
}

@end
