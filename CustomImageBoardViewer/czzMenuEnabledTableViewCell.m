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

#import <QuartzCore/QuartzCore.h>

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate, czzImageDownloaderManagerDelegate>
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *imageFolder;
@property czzSettingsCentre *settingsCentre;
@property UITapGestureRecognizer *tapOnImageGestureRecogniser;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation czzMenuEnabledTableViewCell
@synthesize idLabel;
@synthesize posterLabel;
@synthesize dateLabel;
@synthesize sageLabel;
@synthesize lockLabel;
@synthesize previewImageView;
@synthesize contentTextView;
@synthesize responseLabel;
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
@synthesize tapOnImageGestureRecogniser;
@synthesize delegate;

-(void)awakeFromNib {
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    imageFolder = [czzAppDelegate imageFolder];
    settingsCentre = [czzSettingsCentre sharedInstance];
    shouldHighlight = settingsCentre.userDefShouldHighlightPO;
    self.shouldAllowClickOnImage = YES;
    tapOnImageGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapInImageView:)];
    
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
    UIView *oldButton;
    while ((oldButton = [self viewWithTag:999999]) != nil) {
        [oldButton removeFromSuperview];
    }
    previewImageView.hidden = YES;
    
    sageLabel.hidden = YES;
    lockLabel.hidden = YES;
    responseLabel.hidden = YES;
    
    //colours
    if (settingsCentre.nightyMode) {
        UIColor *viewBackgroundColour = [settingsCentre viewBackgroundColour];
        contentTextView.backgroundColor = viewBackgroundColour;
        idLabel.backgroundColor = viewBackgroundColour;
        posterLabel.backgroundColor = viewBackgroundColour;
        dateLabel.backgroundColor = viewBackgroundColour;
        threadContentView.backgroundColor = viewBackgroundColour;
        self.contentView.backgroundColor = [UIColor darkGrayColor];
    } else {
        contentTextView.backgroundColor = [UIColor whiteColor];
        idLabel.backgroundColor = [UIColor whiteColor];
        dateLabel.backgroundColor = [UIColor whiteColor];
        posterLabel.backgroundColor = [UIColor whiteColor];
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
    DLog(@"reply: %@", sender);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.myThread forKey:@"ReplyToThread"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReplyAction" object:Nil userInfo:userInfo];
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
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.myThread forKey:@"HighlightThread"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HighlightAction" object:Nil userInfo:userInfo];
}

-(void)menuActionSearch:(id) sender {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.myThread forKey:@"SearchUser"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchAction" object:Nil userInfo:userInfo];
}

#pragma mark - consturct UI elements
-(void)prepareUIWithMyThread {
    [self resetViews];
    if (myThread.thImgSrc.length){
        previewImageView.hidden = NO;
        [previewImageView setImage:[UIImage imageNamed:@"Icon.png"]];

        NSString *imageName = myThread.thImgSrc.lastPathComponent;
        UIImage *previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];

        if (settingsCentre.userDefShouldUseBigImage)
        {
            if ([[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
                previewImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:imageName]]];
            }
        }
        if (previewImage){
            [previewImageView setImage:previewImage];
        } 
        //assign a gesture recogniser to it
        [previewImageView setGestureRecognizers:@[tapOnImageGestureRecogniser]];
    }
    //if harmful flag is set, display warning header of harmful thread
    NSMutableAttributedString *contentAttrString;
    if (myThread.content)
        contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:myThread.content];
    if (myThread.harmful){
        NSDictionary *warningStringAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[UIColor lightGrayColor]] forKeys:[NSArray arrayWithObject:NSForegroundColorAttributeName]];
        NSAttributedString *warningAttString = [[NSAttributedString alloc] initWithString:WARNINGHEADER attributes:warningStringAttributes];
        
        //add the warning header to the front of content attributed string
        contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:warningAttString];
        [contentAttrString insertAttributedString:myThread.content atIndex:warningAttString.length];
    }
    //content textview
    if (settingsCentre.nightyMode)
        [contentAttrString addAttribute:NSForegroundColorAttributeName value:settingsCentre.contentTextColour range:NSMakeRange(0, contentAttrString.length)];

    contentTextView.attributedText = contentAttrString;
    contentTextView.font = settingsCentre.contentFont;

    
    idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)myThread.ID];

    NSMutableAttributedString *uidAttrString = [[NSMutableAttributedString alloc] initWithString:@"ID:"];
    if (myThread.UID)
        [uidAttrString appendAttributedString:myThread.UID];
    posterLabel.attributedText = uidAttrString;
    dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];
    if (myThread.sage)
        [sageLabel setHidden:NO];
    if (myThread.lock)
        [lockLabel setHidden:NO];
    if (myThread.responseCount > 0) {
        responseLabel.text = [NSString stringWithFormat:@"回应:%ld", (long)myThread.responseCount];
        responseLabel.hidden = NO;
    }
    
    //clickable content
    for (NSNumber *refNumber in myThread.replyToList) {
        NSInteger rep = refNumber.integerValue;
        if (rep > 0) {
            NSString *quotedNumberText = [NSString stringWithFormat:@"%ld", (long)rep];
            NSRange range = [contentTextView.attributedText.string rangeOfString:quotedNumberText];
            if (range.location != NSNotFound){
                CGRect result = [self frameOfTextRange:range inTextView:contentTextView];
                
                if (!CGSizeEqualToSize(CGSizeZero, result.size)){
                    czzThreadRefButton *threadRefButton = [[czzThreadRefButton alloc] initWithFrame:CGRectMake(result.origin.x, result.origin.y + contentTextView.frame.origin.y, result.size.width, result.size.height)];
                    threadRefButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1f];
                    threadRefButton.tag = 999999;
                    [threadRefButton addTarget:self action:@selector(userTapInQuotedText:) forControlEvents:UIControlEventTouchUpInside];
                    threadRefButton.threadRefNumber = rep;
                    [self.contentView addSubview:threadRefButton];
                }
            }
        }
    }
    
    //highlight original poster
    if (shouldHighlight && parentThread && [myThread.UID.string isEqualToString:parentThread.UID.string]) {
        NSMutableAttributedString *opAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:posterLabel.attributedText];
        [opAttributedString addAttributes:@{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)} range:NSMakeRange(0, opAttributedString.length)];
        posterLabel.attributedText = opAttributedString;
    }
    //highlight the selected user
    else if (selectedUserToHighlight && [myThread.UID.string isEqualToString:selectedUserToHighlight]) {
        contentTextView.backgroundColor = self.contentView.backgroundColor;
    }
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

#pragma - mark UIActionSheet delegate
//Open the link associated with the button
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *hostPrefix = [settingCentre share_post_url];
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
-(void)userTapInQuotedText:(czzThreadRefButton*)sender {
    if ([delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
        [delegate userTapInQuotedText:[NSString stringWithFormat:@"%ld", (long)sender.threadRefNumber]];
    }
}

-(void)userTapInImageView:(id)sender {
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (self.shouldAllowClickOnImage && [delegate respondsToSelector:@selector(userTapInImageView:)]) {
        [delegate userTapInImageView:myThread.imgSrc];
    } else {
        DLog(@"Tap on image view dis-allowed.");
    }
}

#pragma mark - Setters
-(void)setShouldAllowClickOnImage:(BOOL)shouldAllowClickOnImage {
    _shouldAllowClickOnImage = shouldAllowClickOnImage;
    tapOnImageGestureRecogniser.enabled = shouldAllowClickOnImage;
    tapOnImageGestureRecogniser.cancelsTouchesInView = shouldAllowClickOnImage;
}

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

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success && delegate) {
        if (downloader.isThumbnail) {
            if ([downloader.targetURLString.lastPathComponent isEqualToString:myThread.thImgSrc.lastPathComponent]) {
                if ([delegate respondsToSelector:@selector(imageDownloadedForIndexPath:filePath:isThumbnail:)]) {
                    [delegate imageDownloadedForIndexPath:myIndexPath filePath:downloader.savePath isThumbnail:YES];
                }
            }
        }
    }
}

@end
