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
#import "czzMarkerManager.h"

@interface czzThreadTableViewManager ()
@property (nonatomic, strong) PartialTransparentView *containerView;
@property (nonatomic, assign) CGPoint threadsTableViewContentOffSet;
@end

@implementation czzThreadTableViewManager

-(instancetype)init {
    self = [super init];
    if (self) {
        //set up custom edit menu
        UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复"
                                                               action:NSSelectorFromString(@"menuActionReply:")];
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制..."
                                                              action:NSSelectorFromString(@"menuActionCopy:")];
        UIMenuItem *openMenuItem = [[UIMenuItem alloc] initWithTitle:@"打开链接"
                                                              action:NSSelectorFromString(@"menuActionOpen:")];
        UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"标记..."
                                                                   action:NSSelectorFromString(@"menuActionHighlight:")];
        UIMenuItem *blockMenuItem = [[UIMenuItem alloc] initWithTitle:@"屏蔽..."
                                                               action:NSSelectorFromString(@"menuActionBlock:")];
        //    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
        [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, blockMenuItem, /*searchMenuItem,*/ openMenuItem]];
        [[UIMenuController sharedMenuController] update];
        // Rotation observer - remove the container view.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRotationEvent)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    // Remove all notification handlers, this should fix the crashing on iOS 8.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI managements.
-(void)highlightTableViewCell:(NSIndexPath *)indexPath{
    //disable the scrolling view
    self.threadTableView.scrollEnabled = NO;
    self.containerView = [PartialTransparentView new];
    self.containerView.opaque = NO;
    self.containerView.frame = [UIApplication topViewController].view.bounds;
    // Convert the cell rect from within the table view to within the top view.
    CGRect cellRect = [self.threadTableView rectForRowAtIndexPath:indexPath];
    cellRect = [self.threadTableView convertRect:cellRect toView:[UIApplication topViewController].view];
    self.containerView.rectsArray = @[[NSValue valueWithCGRect:cellRect]];
    self.containerView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.7];
    self.containerView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    self.containerView.alpha = 0.0f;
    [[UIApplication topViewController].view addSubview:self.containerView];
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
                         self.containerView = nil;
                         [self.threadTableView reloadData];
                     }];
    
    CGPoint touchPoint = [gestureRecognizer locationInView:[UIApplication topViewController].view];
    NSArray *rectArray = self.containerView.rectsArray;
    // If user touched within the transparent views.
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
        // Thread view cell
        if ([cell isKindOfClass:[czzMenuEnabledTableViewCell class]]){
            czzMenuEnabledTableViewCell *threadViewCell = (czzMenuEnabledTableViewCell*)cell;
            threadViewCell.shouldHighlight = [[czzMarkerManager sharedInstance] isUIDHighlighted:thread.UID];
            threadViewCell.shouldBlock = [[czzMarkerManager sharedInstance] isUIDBlocked:thread.UID];
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
    // When tapping on any row, make all rows resignFirstResponder.
    [tableView.visibleCells makeObjectsPerformSelector:@selector(resignFirstResponder)];
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
    NSInteger threadID = text.integerValue;
    if (!threadID) {
        return;
    }
    NSIndexPath *selectedIndexPath;
    // Use a for loop to find the thread with the given ID.
    for (czzThread *thread in self.threadViewManager.threads) {
        if (threadID == thread.ID) {
            selectedIndexPath = [NSIndexPath indexPathForRow:[self.threadViewManager.threads indexOfObject:thread]
                                                   inSection:0];
            break;
        }
    }
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
    [super userTapInQuotedText:text];
}

- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread{
    DDLogDebug(@"%s : %@", __PRETTY_FUNCTION__, thread);
    [czzReplyUtil replyToThread:thread inParentThread:parentThread];
}

- (void)userWantsToHighlightUser:(NSString *)UID {
    [self.threadViewManager highlightUID:UID];
}

- (void)userWantsToBlockUser:(NSString *)UID {
    [self.threadViewManager blockUID:UID];
}

- (void)userWantsToSearch:(czzThread *)thread {
    DDLogDebug(@"%s : NOT IMPLEMENTED", __PRETTY_FUNCTION__);
}

#pragma mark - Rotation event.
- (void)handleRotationEvent {
    // Remove the container view for any and all rotation event, and re-enable scrolling.
    if (self.containerView) {
        [self.containerView removeFromSuperview];
        self.containerView = nil;
    }
    self.threadTableView.scrollEnabled = YES;
}

#pragma mark - Getter

- (czzHomeViewManager *)homeViewManager {
    return self.threadViewManager;
}

- (czzThreadTableView *)homeTableView {
    return self.threadTableView;
}

@end
