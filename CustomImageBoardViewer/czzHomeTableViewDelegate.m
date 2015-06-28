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
        [NavigationController pushViewController:threadViewController animated:YES];
    }
    else {
        [homeViewManager loadMoreThreads];
        [myTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
