//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeTableViewDelegate.h"

#import "czzMenuEnabledTableViewCell.h"

#import "czzHomeViewModelManager.h"
#import "czzBlacklist.h"
#import "czzThread.h"
#import "czzSettingsCentre.h"
#import "czzThreadViewModelManager.h"

#import "UIApplication+Util.h"
#import "UINavigationController+Util.h"

@interface czzHomeTableViewDelegate()
@property czzHomeViewModelManager *homeViewManager;
@property UITableView *myTableView;
@end

@implementation czzHomeTableViewDelegate
@synthesize homeViewManager;
@synthesize myTableView;

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    DLog(@"%s", __func__);
    czzThread *selectedThread;
    @try {
        if (indexPath.row < homeViewManager.threads.count) {
            selectedThread = [homeViewManager.threads objectAtIndex:indexPath.row];
            if (![settingCentre shouldAllowOpenBlockedThread]) {
                czzBlacklistEntity *blacklistEntity = [[czzBlacklist sharedInstance] blacklistEntityForThreadID:selectedThread.ID];
                if (blacklistEntity){
                    DLog(@"blacklisted thread");
                    return;
                }
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    if (indexPath.row < homeViewManager.threads.count)
    {
        //@todo open the selected thread
        czzThreadViewController *threadViewController = [czzThreadViewController new];
        threadViewController.threadViewModelManager = [[czzThreadViewModelManager alloc] initWithParentThread:selectedThread andForum:homeViewManager.forum];
        
        UINavigationController *rootNavCon = (UINavigationController*)[UIApplication rootViewController];
        if ([rootNavCon isKindOfClass:[UINavigationController class]]) {
            [rootNavCon pushViewController:threadViewController animated:YES];
        } else {
            [[UIApplication rootViewController] presentViewController:threadViewController animated:YES completion:nil];
        }
    }
    else {
        [homeViewManager loadMoreThreads];
        [myTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - UIScrollVIew delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    homeViewManager.currentOffSet = scrollView.contentOffset;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    //    if (onScreenCommandViewController && threads.count > 1 && shouldDisplayQuickScrollCommand) {
    //        [onScreenCommandViewController show];
    //    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    //    NSArray *visibleRows = [threadTableView visibleCells];
    //    UITableViewCell *lastVisibleCell = [visibleRows lastObject];
    //    NSIndexPath *path = [threadTableView indexPathForCell:lastVisibleCell];
    //    if(path.row == threads.count && threads.count > 0)
    //    {
    //        CGRect lastCellRect = [threadTableView rectForRowAtIndexPath:path];
    //        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.frame.size.height && !(threadList.isDownloading || threadList.isProcessing)){
    //            [threadList loadMoreThreads];
    //            [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    //        }
    //    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!myTableView) {
        myTableView = tableView;
    }
    if (indexPath.row >= homeViewManager.threads.count)
        return tableView.rowHeight;
    
    NSArray *heightArray = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? homeViewManager.verticalHeights : homeViewManager.horizontalHeights;
    CGFloat preferHeight = tableView.rowHeight;
    @try {
        preferHeight = [[heightArray objectAtIndex:indexPath.row] floatValue];
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    return preferHeight;
}

+(instancetype)initWithViewModelManager:(czzHomeViewModelManager *)viewModelManager {
    czzHomeTableViewDelegate *sharedDelegate = [czzHomeTableViewDelegate sharedInstance];
    sharedDelegate.homeViewManager = viewModelManager;
    return sharedDelegate;
}

+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

@end
