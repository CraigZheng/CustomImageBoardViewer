//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadViewDelegate.h"

#import "PartialTransparentView.h"
#import "czzThreadRefButton.h"

@interface czzThreadViewDelegate ()
@property (nonatomic, strong) PartialTransparentView *containerView;
@property (nonatomic, assign) CGPoint threadsTableViewContentOffSet;
@end

@implementation czzThreadViewDelegate

-(instancetype)init {
    self = [super init];
    if (self) {
        //set up custom edit menu
        UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:NSSelectorFromString(@"menuActionReply:")];
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:NSSelectorFromString(@"menuActionCopy:")];
        UIMenuItem *openMenuItem = [[UIMenuItem alloc] initWithTitle:@"打开链接" action:NSSelectorFromString(@"menuActionOpen:")];
        UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"高亮他" action:NSSelectorFromString(@"menuActionHighlight:")];
        //    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
        [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, /*searchMenuItem,*/ openMenuItem]];
        [[UIMenuController sharedMenuController] update];
    }
    return self;
}

#pragma mark - UI managements.
-(void)highlightTableViewCell:(UITableViewCell*)tableviewcell{
    //disable the scrolling view
    self.myTableView.scrollEnabled = NO;
    if (!self.containerView) {
        self.containerView = [PartialTransparentView new];
        self.containerView.opaque = NO;
    }
    
    self.containerView.frame = CGRectMake(self.myTableView.frame.origin.x, self.myTableView.frame.origin.y, self.myTableView.frame.size.width, self.myTableView.contentSize.height);
    self.containerView.rectsArray = [NSArray arrayWithObject:[NSValue valueWithCGRect:tableviewcell.frame]];
    self.containerView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.7];
    
    self.containerView.userInteractionEnabled = YES;
    [self.containerView setNeedsDisplay];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    self.containerView.alpha = 0.0f;
    [self.myTableView addSubview:self.containerView];
    [UIView animateWithDuration:0.2
                     animations:^{self.containerView.alpha = 1.0f;}
                     completion:^(BOOL finished){[self.containerView addGestureRecognizer:tapRecognizer];}];
    
}

-(void)tapOnFloatingView:(id)sender {
    UIGestureRecognizer *gestureRecognizer = sender;
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.containerView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.containerView removeFromSuperview];
                         [self.myTableView reloadData];
                     }];
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.myTableView];
    NSArray *rectArray = self.containerView.rectsArray;
    BOOL userTouchInView = NO;
    for (NSValue *rect in rectArray) {
        if (CGRectContainsPoint([rect CGRectValue], touchPoint)) {
            userTouchInView = YES;
            break;
        }
    }
    
    if (!userTouchInView)
        [self.myTableView setContentOffset:self.threadsTableViewContentOffSet animated:YES];
    self.myTableView.scrollEnabled = YES;

}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

#pragma mark - UI actions

-(void)userTapInRefButton:(czzThreadRefButton *)button {
    [self userTapInQuotedText:[NSString stringWithFormat:@"%ld", (long)button.threadRefNumber]];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    czzMenuEnabledTableViewCell *threadViewCell;
    if ([cell isKindOfClass:[czzMenuEnabledTableViewCell class]]) {
        threadViewCell = (czzMenuEnabledTableViewCell*)cell;
    } else {
        return;
    }
    // Clear the content view for previous czzThreadRefButton.
    for (UIView *subView in threadViewCell.contentView.subviews) {
        if ([subView isKindOfClass:[czzThreadRefButton class]]) {
            [subView removeFromSuperview];
        }
    }
    
    // Clickable content, find the quoted text and add a button to corresponding location.
    for (NSNumber *refNumber in threadViewCell.myThread.replyToList) {
        NSInteger rep = refNumber.integerValue;
        if (rep > 0) {
            NSString *quotedNumberText = [NSString stringWithFormat:@"%ld", (long)rep];
            NSRange range = [threadViewCell.contentTextView.attributedText.string rangeOfString:quotedNumberText];
            if (range.location != NSNotFound){
                CGRect result = [self frameOfTextRange:range inTextView:threadViewCell.contentTextView];
                
                if (!CGSizeEqualToSize(CGSizeZero, result.size)){
                    czzThreadRefButton *threadRefButton = [[czzThreadRefButton alloc] initWithFrame:CGRectMake(result.origin.x, result.origin.y + threadViewCell.contentTextView.frame.origin.y, result.size.width, result.size.height)];
                    threadRefButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1f];
                    threadRefButton.tag = 999999;
                    [threadRefButton addTarget:self action:@selector(userTapInRefButton:) forControlEvents:UIControlEventTouchUpInside];
                    threadRefButton.threadRefNumber = rep;
                    [threadViewCell.contentView addSubview:threadRefButton];
                }
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.threadViewManager.threads.count) {
        
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.threadViewManager.threads.count) {
        return YES;
    }
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
}

#pragma mark - czzMenuEnableTableViewCellDelegate
- (void)userTapInQuotedText:(NSString *)text {
    // Text cannot be parsed to an integer, return...
    text = [text componentsSeparatedByString:@"/"].lastObject;
    if (!text.integerValue) {
        return;
    }
    for (czzThread *thread in self.threadViewManager.threads) {
        if (thread.ID == text.integerValue) {
            self.threadsTableViewContentOffSet = self.myTableView.contentOffset;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.threadViewManager.threads indexOfObject:thread] inSection:0];
            [self.myTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
            [[NSOperationQueue currentQueue] addOperationWithBlock:^{
                [self highlightTableViewCell:[self.myTableView cellForRowAtIndexPath:indexPath]];
            }];
            return;
        }
    }

    // Thread not found in the downloaded thread, get it from server instead.
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"正在下载: %ld", (long)text.integerValue]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        czzThread * thread = [[czzThread alloc] initWithThreadID:text.integerValue];
        // After return, run the remaining codes in main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (thread) {
                [self.threadViewManager showContentWithThread:thread];
            } else {
                [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"找不到引用串：%ld", thread.ID]];
            }
        });
    });
}

#pragma mark - Accessors

-(czzThreadViewManager *)threadViewManager {
    return (id)[super homeViewManager];
}

- (void)setThreadViewManager:(czzThreadViewManager *)threadViewManager {
    [super setHomeViewManager:threadViewManager];
}

+(instancetype)initWithViewManager:(czzHomeViewManager *)viewManager andTableView:(czzThreadTableView *)tableView {
    czzThreadViewDelegate *threadViewDelegate = [[czzThreadViewDelegate alloc] init];
    threadViewDelegate.homeViewManager = viewManager;
    threadViewDelegate.myTableView = tableView;
    return threadViewDelegate;
}


@end
