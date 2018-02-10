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
#import "czzThreadViewCellHeaderView.h"
#import "CustomImageBoardViewer-Swift.h"

@interface czzThreadTableViewManager ()
@property (nonatomic, strong) PartialTransparentView *containerView;
@property (nonatomic, assign) CGPoint threadsTableViewContentOffSet;
@property (nonatomic, strong) NSString *temporarilyHighlightUID;
@end

@implementation czzThreadTableViewManager

-(instancetype)init {
    self = [super init];
    if (self) {
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
-(void)highlightTableViewCell:(NSIndexPath *)indexPath {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    // If within the range of threads, is a thread view cell, otherwise is a command cell.
    ContentPage *currentPage = self.threadViewManager.threads[indexPath.section];
    if (indexPath.row < currentPage.count) {
        czzThread *thread = currentPage.threads[indexPath.row];
        // Thread view cell
        if ([cell isKindOfClass:[czzMenuEnabledTableViewCell class]]){
            czzMenuEnabledTableViewCell *threadViewCell = (czzMenuEnabledTableViewCell*)cell;
            threadViewCell.shouldBlock = [[czzMarkerManager sharedInstance] isUIDBlocked:thread.UID];
            threadViewCell.cellType = threadViewCellTypeThread;
            threadViewCell.parentThread = self.threadViewManager.parentThread;
            threadViewCell.shouldTemporarilyHighlight = [self.temporarilyHighlightUID isEqualToString:thread.UID];
            threadViewCell.cellHeaderView.headerButton.enabled = NO;
            threadViewCell.cellHeaderView.headerButton.hidden = YES;
            if (self.threadViewManager.threads.count >= 2) {
                ContentPage *firstPage = self.threadViewManager.threads[0];
                ContentPage *secondPage = self.threadViewManager.threads[1];
                if (currentPage == self.threadViewManager.threads.firstObject) {
                    if (firstPage.pageNumber + 1 != secondPage.pageNumber) {
                        threadViewCell.cellHeaderView.headerButton.enabled = YES;
                        threadViewCell.cellHeaderView.headerButton.hidden = NO;
                        
                        [threadViewCell.cellHeaderView.headerButton setTitle:[NSString stringWithFormat:@"点击以加载第 %ld 页的内容", secondPage.pageNumber - 1]
                                                                    forState:UIControlStateNormal];
                    }
                } else if (secondPage.pageNumber != 1 && thread == secondPage.threads.firstObject) {
                    threadViewCell.cellHeaderView.headerButton.enabled = NO;
                    threadViewCell.cellHeaderView.headerButton.hidden = NO;
                    [threadViewCell.cellHeaderView.headerButton setTitle:[NSString stringWithFormat:@"以下为 %ld 页起的内容", (long)secondPage.pageNumber]
                                                                forState:UIControlStateNormal];
                }
                threadViewCell.cellHeaderView.headerButtonContainerViewHeightConstraint.constant = threadViewCell.cellHeaderView.headerButton.isHidden ? 0 : 46;
            }
            
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
    if (indexPath.row < self.threadViewManager.threads[indexPath.section].threads.count) {
        
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return !(indexPath.section == tableView.lastSection && indexPath.row == tableView.lastRow);
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
    for (ContentPage *contentPage in self.threadViewManager.threads) {
        for (czzThread *thread in contentPage.threads) {
            if (thread.ID == threadID) {
                selectedIndexPath = [NSIndexPath indexPathForRow:[contentPage.threads indexOfObject:thread]
                                                       inSection:[self.threadViewManager.threads indexOfObject:contentPage]];
                break;
            }
        }
    }
    if (selectedIndexPath) {
        self.threadsTableViewContentOffSet = self.threadTableView.contentOffset;
        [self.threadTableView scrollToRowAtIndexPath:selectedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        [[NSOperationQueue currentQueue] addOperationWithBlock:^{
            [self highlightTableViewCell:selectedIndexPath];
        }];
        return;    
    }
    
    // Thread not found in the downloaded thread, get it from server instead.
    [super userTapInQuotedText:text];
}

- (void)userWantsToTemporarilyHighlightUser:(NSString *)UID {
    if ([self.temporarilyHighlightUID isEqualToString:UID]) {
        self.temporarilyHighlightUID = nil;
    } else {
        self.temporarilyHighlightUID = UID;
    }
    [self reloadData];
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
