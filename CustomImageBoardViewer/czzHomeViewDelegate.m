//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeViewDelegate.h"

#import "czzMenuEnabledTableViewCell.h"

#import "czzHomeViewModelManager.h"
#import "czzBlacklist.h"
#import "czzThread.h"
#import "czzSettingsCentre.h"
#import "czzThreadTableView.h"
#import "czzImageViewerUtil.h"
#import "czzThreadViewModelManager.h"

#import "UIApplication+Util.h"
#import "UINavigationController+Util.h"

@interface czzHomeViewDelegate()

@property (strong) czzImageViewerUtil *imageViewerUtil;
@property (strong) NSMutableDictionary *cachedCells;
@end

@implementation czzHomeViewDelegate

-(instancetype)init {
    self = [super init];
    if (self) {
        self.imageViewerUtil = [czzImageViewerUtil new];
        self.cachedCells = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.myTableView) {
        self.myTableView = (czzThreadTableView*)tableView;
    }
    czzThread *selectedThread;
    @try {
        if (indexPath.row < self.viewModelManager.threads.count) {
            selectedThread = [self.viewModelManager.threads objectAtIndex:indexPath.row];
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
    if (indexPath.row < self.viewModelManager.threads.count)
    {
        //@todo open the selected thread
        czzThreadViewController *threadViewController = [czzThreadViewController new];
        threadViewController.threadViewModelManager = [[czzThreadViewModelManager alloc] initWithParentThread:selectedThread andForum:self.viewModelManager.forum];
        [NavigationManager pushViewController:threadViewController animated:YES];
    }
    else {
        [self.viewModelManager loadMoreThreads];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.myTableView) {
        self.myTableView = (czzThreadTableView*)tableView;
    }
    
    if (indexPath.row < self.viewModelManager.threads.count) {
        NSString *cell_identifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
        czzThread *thread = [self.viewModelManager.threads objectAtIndex:indexPath.row];
        
        static czzMenuEnabledTableViewCell *cell = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            cell = [self.myTableView dequeueReusableCellWithIdentifier:cell_identifier];
        });
        
        if (cell){
            cell.shouldHighlight = NO;
            cell.shouldAllowClickOnImage = ![settingCentre userDefShouldUseBigImage];
            cell.parentThread = thread;
            cell.myIndexPath = indexPath;
            cell.myThread = thread;
        }
        
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGSize systemDesiredSize = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        CGFloat desiredHeight = systemDesiredSize.height + 20;
        return desiredHeight;
    } else {
        return self.myTableView.rowHeight;
    }
    /*
    if (indexPath.row >= self.viewModelManager.threads.count)
        return tableView.rowHeight;
    
    NSArray *heightArray = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? self.viewModelManager.verticalHeights : self.viewModelManager.horizontalHeights;
    CGFloat preferHeight = tableView.rowHeight;
    @try {
        preferHeight = [[heightArray objectAtIndex:indexPath.row] floatValue];
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    return preferHeight;
     */
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([settingCentre userDefShouldShowOnScreenCommand]) {
        [self.myTableView.upDownViewController show];
    }
}

#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    [self.imageViewerUtil showPhoto:imgURL inViewController:NavigationManager.delegate];
}

-(void)imageDownloadedForIndexPath:(NSIndexPath *)index filePath:(NSString *)path isThumbnail:(BOOL)isThumbnail {
    if (isThumbnail) {
        @try {
            [self.myTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
    }
}

#pragma mark - czzOnScreenImageManagerViewControllerDelegate
-(void)onScreenImageManagerDownloadFinished:(czzOnScreenImageManagerViewController *)controller imagePath:(NSString *)path wasSuccessful:(BOOL)success {
    if (success) {
        if ([settingCentre userDefShouldAutoOpenImage])
            [self.imageViewerUtil showPhoto:path inViewController:NavigationManager.delegate];
    } else
        DLog(@"img download failed");
}

-(void)onScreenImageManagerSelectedImage:(NSString *)path {
    [self.imageViewerUtil showPhoto:path inViewController:NavigationManager.delegate];
}

#pragma mark - setters
-(void)setMyTableView:(czzThreadTableView *)myTableView {
    _myTableView = myTableView;
    _myTableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

+(instancetype)initWithViewModelManager:(czzHomeViewModelManager *)viewModelManager {
    czzHomeViewDelegate *sharedDelegate = [czzHomeViewDelegate sharedInstance];
    sharedDelegate.viewModelManager = viewModelManager;
    return sharedDelegate;
}

+ (instancetype)sharedInstance
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
