//
//  czzMenuEnabledTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****\n\n"


#import "czzMenuEnabledTableViewCell.h"
#import "czzPostViewController.h"
#import "czzAppDelegate.h"
#import "czzImageCentre.h"
#import "DACircularProgressView.h"
#import "czzSettingsCentre.h"
#import "czzThreadRefButton.h"

@interface czzMenuEnabledTableViewCell()<UIActionSheetDelegate>
@property NSString *thumbnailFolder;
@property czzSettingsCentre *settingsCentre;
@property UITapGestureRecognizer *tapOnImageGestureRecogniser;
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
@synthesize circularProgressView;

@synthesize settingsCentre;
@synthesize shouldHighlight;
@synthesize shouldHighlightSelectedUser;
@synthesize links;
@synthesize parentThread;
@synthesize myThread;
@synthesize thumbnailFolder;
@synthesize downloadedImages;
@synthesize tapOnImageGestureRecogniser;
@synthesize delegate;

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        thumbnailFolder = [czzAppDelegate libraryFolder];
        thumbnailFolder = [thumbnailFolder stringByAppendingPathComponent:@"Thumbnails"];
        settingsCentre = [czzSettingsCentre sharedInstance];
        shouldHighlight = settingsCentre.userDefShouldHighlightPO;
        tapOnImageGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapInImageView:)];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        thumbnailFolder = [czzAppDelegate libraryFolder];
        thumbnailFolder = [thumbnailFolder stringByAppendingPathComponent:@"Thumbnails"];
        settingsCentre = [czzSettingsCentre sharedInstance];
        shouldHighlight = settingsCentre.userDefShouldHighlightPO;

        tapOnImageGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapInImageView:)];
    }
    return self;
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

-(void)prepareForReuse{
    UIView *viewToRemove = [self viewWithTag:99];
    if (viewToRemove){
        [viewToRemove removeFromSuperview];
    }
}

#pragma mark - custom menu action
-(void)menuActionCopy:(id)sender{
    [[UIPasteboard generalPasteboard] setString:self.myThread.content.string];
    [[czzAppDelegate sharedAppDelegate] showToast:@"内容已复制"];
}

-(void)menuActionReply:(id)sender{
    NSLog(@"reply: %@", sender);
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

#pragma mark - setter
-(void)setMyThread:(czzThread *)thread{
    myThread = thread;
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
    [self prepareUIWithMyThread];
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

#pragma mark - consturct UI elements
-(void)prepareUIWithMyThread {
    previewImageView.hidden = YES;
    circularProgressView.hidden = YES;
    if (myThread.thImgSrc.length != 0){
        previewImageView.hidden = NO;
        [previewImageView setImage:[UIImage imageNamed:@"Icon.png"]];
        NSString *filePath = [thumbnailFolder stringByAppendingPathComponent:[myThread.thImgSrc.lastPathComponent stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
        UIImage *previewImage =[[UIImage alloc] initWithContentsOfFile:filePath];
        if (previewImage){
            [previewImageView setImage:previewImage];
        } else if ([downloadedImages objectForKey:myThread.thImgSrc]){
            [previewImageView setImage:[[UIImage alloc] initWithContentsOfFile:[downloadedImages objectForKey:myThread.thImgSrc]]];
        }
        //assign a gesture recogniser to it
        [previewImageView setGestureRecognizers:@[tapOnImageGestureRecogniser]];
    }
    //if harmful flag is set, display warning header of harmful thread
    NSMutableAttributedString *contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:myThread.content];
    if (myThread.harmful){
        NSDictionary *warningStringAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[UIColor lightGrayColor]] forKeys:[NSArray arrayWithObject:NSForegroundColorAttributeName]];
        NSAttributedString *warningAttString = [[NSAttributedString alloc] initWithString:WARNINGHEADER attributes:warningStringAttributes];
        
        //add the warning header to the front of content attributed string
        contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:warningAttString];
        [contentAttrString insertAttributedString:myThread.content atIndex:warningAttString.length];
    }
    //content textview
    contentTextView.attributedText = contentAttrString;
    contentTextView.font = settingsCentre.contentFont;
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 7.0) {
        NSMutableAttributedString *tempAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:contentTextView.attributedText];
        [tempAttributedString addAttribute:NSFontAttributeName value:settingsCentre.contentFont range:NSMakeRange(0, tempAttributedString.length)];
        contentTextView.attributedText = tempAttributedString;
    }
    
    idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)myThread.ID];
    //set the color
    NSMutableAttributedString *uidAttrString = [[NSMutableAttributedString alloc] initWithString:@"UID:"];
    [uidAttrString appendAttributedString:myThread.UID];
    posterLabel.attributedText = uidAttrString;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"时间:yyyy MM-dd, HH:mm"];
    dateLabel.text = [dateFormatter stringFromDate:myThread.postDateTime];
    if (myThread.sage)
        [sageLabel setHidden:NO];
    else
        [sageLabel setHidden:YES];
    if (myThread.lock)
        [lockLabel setHidden:NO];
    else
        [lockLabel setHidden:YES];
    if (parentThread && myThread && [myThread.UID.string isEqualToString:parentThread.UID.string])
    {
        responseLabel.text = [NSString stringWithFormat:@"回应:%ld", (long)myThread.responseCount];
    } else {
        responseLabel.hidden = YES;
    }
    
    //clickable content
    UIView *oldButton;
    while ((oldButton = [self viewWithTag:999999]) != nil) {
        [oldButton removeFromSuperview];
    }
    for (NSNumber *refNumber in myThread.replyToList) {
        NSInteger rep = refNumber.integerValue;
        if (rep > 0 && contentTextView) {
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
    posterLabel.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    if (shouldHighlight && parentThread && [myThread.UID.string isEqualToString:parentThread.UID.string]) {
        posterLabel.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:200.0f/255.0f alpha:1.0];
        self.contentView.backgroundColor = [UIColor clearColor];
    } else if (shouldHighlightSelectedUser && [myThread.UID.string isEqualToString:shouldHighlightSelectedUser]) {
        posterLabel.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor colorWithRed:222.0f/255.0f green:222.0f/255.0f blue:255.0f/255.0f alpha:1.0];
    }
}

#pragma - mark UIActionSheet delegate
//Open the link associated with the button
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSURL *link = [NSURL URLWithString:buttonTitle];
    [[UIApplication sharedApplication] openURL:link];
}

#pragma mark - user actions
-(void)userTapInQuotedText:(czzThreadRefButton*)sender {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (delegate && [delegate respondsToSelector:@selector(userTapInQuotedText:)]) {
        [delegate userTapInQuotedText:[NSString stringWithFormat:@"%ld", (long)sender.threadRefNumber]];
    }
}

-(void)userTapInImageView:(id)sender {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (delegate && [delegate respondsToSelector:@selector(userTapInImageView:)]) {
        for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
            if ([file.lastPathComponent.lowercaseString isEqualToString:myThread.imgSrc.lastPathComponent.lowercaseString])
            {
                [delegate userTapInImageView:file];
                return;
            }
        }
        //Start or stop the image downloader
        if ([[czzImageCentre sharedInstance] containsImageDownloaderWithURL:myThread.imgSrc]){
            [[czzImageCentre sharedInstance] stopAndRemoveImageDownloaderWithURL:myThread.imgSrc];
            [[czzAppDelegate sharedAppDelegate] showToast:@"图片下载被终止了"];
            NSLog(@"stop: %@", myThread.imgSrc);
        } else {
            BOOL completedURL = NO;
            if ([[[NSURL URLWithString:myThread.imgSrc] scheme] isEqualToString:@"http"]) {
                completedURL = YES;
            } else {
                myThread.imgSrc = [[[czzSettingsCentre sharedInstance] image_host] stringByAppendingPathComponent:myThread.imgSrc];
                completedURL = YES;
            }
            NSLog(@"start : %@", myThread.imgSrc);
            [[czzImageCentre sharedInstance] downloadImageWithURL:myThread.imgSrc isCompletedURL:completedURL];
            [[czzAppDelegate sharedAppDelegate] showToast:@"正在下载图片"];
        }

    }
}
@end
