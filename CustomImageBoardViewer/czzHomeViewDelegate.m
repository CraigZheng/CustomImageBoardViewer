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
@property (nonatomic, readonly) NSIndexPath *lastRowIndexPath;
@property (nonatomic, readonly) BOOL tableViewIsDraggedOverTheBottom;
- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding;
@end

@implementation czzHomeViewDelegate

-(instancetype)init {
    self = [super init];
    if (self) {
        self.imageViewerUtil = [czzImageViewerUtil new];
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
        NSArray *threads = self.viewModelManager.threads;
        if (indexPath.row < threads.count) {
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
        threadViewController.viewModelManager = [[czzThreadViewModelManager alloc] initWithParentThread:selectedThread andForum:self.viewModelManager.forum];
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
    if (indexPath.row >= self.viewModelManager.threads.count)
        return tableView.rowHeight;
    
    NSArray *heightArray = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? self.viewModelManager.verticalHeights : self.viewModelManager.horizontalHeights;
    CGFloat preferHeight = tableView.rowHeight;
    @try {
        if (indexPath.row < heightArray.count)
            preferHeight = [[heightArray objectAtIndex:indexPath.row] floatValue];
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    return preferHeight;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([settingCentre userDefShouldShowOnScreenCommand]) {
        [self.myTableView.upDownViewController show];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!(self.viewModelManager.isDownloading || self.viewModelManager.isProcessing) && self.viewModelManager.threads.count > 0) {
        if (self.tableViewIsDraggedOverTheBottom) {
            if ([self tableViewIsDraggedOverTheBottomWithPadding:44 * 2]) {
                self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore;
            } else {
                if (self.myTableView.lastCellType != czzThreadViewCommandStatusCellViewTypeLoadMore) {
                    self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
                }
            }
        }
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!(self.viewModelManager.isDownloading || self.viewModelManager.isProcessing) && self.viewModelManager.threads.count > 0) {
        if ([self tableViewIsDraggedOverTheBottomWithPadding:44 * 2]) {
            [self.viewModelManager loadMoreThreads];
            [self.myTableView reloadRowsAtIndexPaths:@[self.lastRowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    // If image exists
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
        {
            // Show image and return.
            [self.imageViewerUtil showPhoto:file];
            return;
        }
    }
    // Image not found in local storage, start or stop the image downloader with the image URL
    if ([[czzImageCentre sharedInstance] containsImageDownloaderWithURL:imgURL]){
        [[czzImageCentre sharedInstance] stopAndRemoveImageDownloaderWithURL:imgURL];
        [AppDelegate showToast:@"下载终止"];
        DLog(@"stop: %@", imgURL);
    } else {
        if (![[[NSURL URLWithString:imgURL] scheme] hasPrefix:@"http"]) {
            imgURL = [[[czzSettingsCentre sharedInstance] image_host] stringByAppendingPathComponent:imgURL];
        }
        DLog(@"start : %@", imgURL);
        [[czzImageCentre sharedInstance] downloadImageWithURL:imgURL isCompletedURL:YES];
    }
}

-(void)imageDownloadedForIndexPath:(NSIndexPath *)index filePath:(NSString *)path isThumbnail:(BOOL)isThumbnail {
    if (isThumbnail) {
        @try {
            if (index.row < self.viewModelManager.threads.count)
                [self.myTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        @catch (NSException *exception) {
            [self.myTableView reloadData];
            DLog(@"%@", exception);
        }
    }
}

#pragma mark - czzOnScreenImageManagerViewControllerDelegate
-(void)onScreenImageManagerDownloadFinished:(czzOnScreenImageManagerViewController *)controller imagePath:(NSString *)path wasSuccessful:(BOOL)success {
    if (success) {
        if ([settingCentre userDefShouldAutoOpenImage])
            [self.imageViewerUtil showPhoto:path];
    } else
        DLog(@"img download failed");
}

-(void)onScreenImageManagerSelectedImage:(NSString *)path {
    [self.imageViewerUtil showPhoto:path];
}

#pragma mark - Getters {
- (BOOL)tableViewIsDraggedOverTheBottom {
    return [self tableViewIsDraggedOverTheBottomWithPadding:44];
}

- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding {
    BOOL isOver = NO;
    @try {
        if (self.myTableView.window) {
            UITableViewCell *lastVisibleCell = [[self.myTableView visibleCells] lastObject];
            if (lastVisibleCell) {
                NSIndexPath *path = [self.myTableView indexPathForCell:lastVisibleCell];
                if (path.row == self.viewModelManager.threads.count)
                {
                    CGPoint contentOffSet = self.myTableView.contentOffset;
                    CGRect lastCellRect = [self.myTableView rectForRowAtIndexPath:path];
                    if (lastCellRect.origin.y + lastCellRect.size.height + padding < contentOffSet.y + self.myTableView.frame.size.height) {
                        isOver = YES;
                    } else {
                        isOver = NO;
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return isOver;
}

- (NSIndexPath *)lastRowIndexPath {
    return [NSIndexPath indexPathForRow:self.viewModelManager.threads.count inSection:0];
}

#pragma marl - Setters
- (void)setMyTableView:(czzThreadTableView *)myTableView {
    _myTableView = myTableView;
    if (myTableView) {
    }
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
