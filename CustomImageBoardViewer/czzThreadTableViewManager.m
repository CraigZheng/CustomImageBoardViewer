//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableViewManager.h"

#import "PartialTransparentView.h"
#import "czzThreadRefButton.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzReplyUtil.h"

@interface czzThreadTableViewManager ()
@property (nonatomic, strong) PartialTransparentView *containerView;
@property (nonatomic, assign) CGPoint threadsTableViewContentOffSet;
@end

@implementation czzThreadTableViewManager

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
-(void)highlightTableViewCell:(NSIndexPath *)indexPath{
    //disable the scrolling view
    self.threadTableView.scrollEnabled = NO;
    self.containerView = [PartialTransparentView new];
    self.containerView.opaque = NO;
    self.containerView.frame = CGRectMake(0, 0, self.threadTableView.contentSize.width, self.threadTableView.contentSize.height);
    CGRect cellRect = [self.threadTableView rectForRowAtIndexPath:indexPath];
    self.containerView.rectsArray = @[[NSValue valueWithCGRect:cellRect]];
    self.containerView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.7];
    self.containerView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    self.containerView.alpha = 0.0f;
    [self.threadTableView addSubview:self.containerView];
    [UIView animateWithDuration:0.2
                     animations:^{self.containerView.alpha = 1.0f;}
                     completion:^(BOOL finished){
                         [self.containerView addGestureRecognizer:tapRecognizer];
                     }];
    
}

-(void)tapOnFloatingView:(id)sender {
    UIGestureRecognizer *gestureRecognizer = sender;
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.containerView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.containerView removeFromSuperview];
                         [self.threadTableView reloadData];
                     }];
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.threadTableView];
    NSArray *rectArray = self.containerView.rectsArray;
    BOOL userTouchInView = NO;
    for (NSValue *rect in rectArray) {
        if (CGRectContainsPoint([rect CGRectValue], touchPoint)) {
            userTouchInView = YES;
            break;
        }
    }
    
    if (!userTouchInView)
        [self.threadTableView setContentOffset:self.threadsTableViewContentOffSet animated:YES];
    self.threadTableView.scrollEnabled = YES;

}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    // If within the range of threads, is a thread view cell, otherwise is a command cell.
    if (indexPath.row < self.threadViewManager.threads.count) {
        czzThread *thread = [self.threadViewManager.threads objectAtIndex:indexPath.row];
        [self.threadViewManager.referenceIndexDictionary setObject:[indexPath copy] forKey:[NSString stringWithFormat:@"%ld", (long)thread.ID]];
        // Thread view cell
        if ([cell isKindOfClass:[czzMenuEnabledTableViewCell class]]){
            czzMenuEnabledTableViewCell *threadViewCell = (czzMenuEnabledTableViewCell*)cell;
            threadViewCell.shouldHighlight = YES;
            threadViewCell.selectedUserToHighlight = self.threadViewManager.selectedUserToHighlight;
            threadViewCell.cellType = threadViewCellTypeThread;
            threadViewCell.parentThread = self.threadViewManager.parentThread;
            [threadViewCell renderContent];
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    czzMenuEnabledTableViewCell *threadViewCell;
    if ([cell isKindOfClass:[czzMenuEnabledTableViewCell class]]) {
        threadViewCell = (czzMenuEnabledTableViewCell*)cell;
    } else {
        return;
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
    NSIndexPath *selectedIndexPath = [self.threadViewManager.referenceIndexDictionary objectForKey:text];
    if (selectedIndexPath && selectedIndexPath.row < self.threadViewManager.threads.count) {
        czzThread *selectedThread = [self.threadViewManager.threads objectAtIndex:selectedIndexPath.row];
        if (selectedThread.ID == text.integerValue) {
            self.threadsTableViewContentOffSet = self.threadTableView.contentOffset;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.threadViewManager.threads indexOfObject:selectedThread] inSection:0];
            [self.threadTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
            [[NSOperationQueue currentQueue] addOperationWithBlock:^{
                [self highlightTableViewCell:indexPath];
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
                [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"找不到引用串：%ld", (long)thread.ID]];
            }
        });
    });
}

- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread{
    DDLogDebug(@"%s : %@", __PRETTY_FUNCTION__, thread);
    [czzReplyUtil replyToThread:thread inParentThread:parentThread];
}

- (void)userWantsToHighLight:(czzThread *)thread {
    DDLogDebug(@"%s : %@", __PRETTY_FUNCTION__, thread);
    if ([self.homeViewManager isKindOfClass:[czzThreadViewManager class]]) {
        [(czzThreadViewManager *)self.homeViewManager HighlightThreadSelected:thread];
    }
}

- (void)userWantsToSearch:(czzThread *)thread {
    DDLogDebug(@"%s : NOT IMPLEMENTED", __PRETTY_FUNCTION__);
}

#pragma mark - Getter

- (czzHomeViewManager *)homeViewManager {
    return self.threadViewManager;
}

- (czzThreadTableView *)homeTableView {
    return self.threadTableView;
}

@end
