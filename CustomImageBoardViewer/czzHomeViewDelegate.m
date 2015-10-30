//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeViewDelegate.h"

#import "czzMenuEnabledTableViewCell.h"

#import "czzHomeViewManager.h"
#import "czzBlacklist.h"
#import "czzThread.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzSettingsCentre.h"
#import "czzThreadTableView.h"
#import "czzImageViewerUtil.h"
#import "czzThreadViewManager.h"

#import "UIApplication+Util.h"
#import "UINavigationController+Util.h"

@interface czzHomeViewDelegate() <czzImageDownloaderManagerDelegate>

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
        [[czzImageDownloaderManager sharedManager] addDelegate:self];
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
        threadViewController.viewModelManager = [[czzThreadViewManager alloc] initWithParentThread:selectedThread andForum:self.viewModelManager.forum];
        [NavigationManager pushViewController:threadViewController animated:YES];
    }
    // If not downloading or processing, load more threads.
    else if (!self.viewModelManager.isDownloading || !self.viewModelManager.isProcessing) {
        [self.viewModelManager loadMoreThreads];
        [tableView reloadData];
//        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat estimatedRowHeight = 44;
    if (indexPath.row < self.homeViewManager.threads.count) {
        czzThread *thread = [self.homeViewManager.threads objectAtIndex:indexPath.row];
        // If the height is already available.
        NSString *threadID = [NSString stringWithFormat:@"%ld", (long)thread.ID];
        NSMutableDictionary *heightDictionary = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? self.homeViewManager.verticalHeights : self.homeViewManager.horizontalHeights;

        id cachedHeight = [heightDictionary objectForKey:threadID];
        if ([cachedHeight isKindOfClass:[NSNumber class]]) {
            estimatedRowHeight = [cachedHeight floatValue];
        } else {
            NSInteger estimatedLines = thread.content.length / 50 + 1;
            estimatedRowHeight *= estimatedLines;
            
            // Has image = bigger.
            if (thread.thImgSrc.length) {
                estimatedRowHeight += settingCentre.userDefShouldUseBigImage ? 160 : 80;
            }
        }
    }
    return estimatedRowHeight;
}

//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (!self.myTableView) {
//        self.myTableView = (czzThreadTableView*)tableView;
//    }
//    if (indexPath.row >= self.homeViewManager.threads.count)
//        return tableView.rowHeight;
//    
//    CGFloat preferHeight = tableView.rowHeight;
//    czzThread *thread = [self.homeViewManager.threads objectAtIndex:indexPath.row];
//    NSString *threadID = [NSString stringWithFormat:@"%ld", (long)thread.ID];
//    
//    NSMutableDictionary *heightDictionary = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? self.homeViewManager.verticalHeights : self.homeViewManager.horizontalHeights;
//    
//    NSNumber *heightNumber = [heightDictionary objectForKey:threadID];
//    if ([heightNumber isKindOfClass:[NSNumber class]]) {
//        preferHeight = [heightNumber floatValue];
//    } else {
//        preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:self.myTableView hasImage:thread.thImgSrc.length];
//        heightNumber = @(preferHeight);
//        [heightDictionary setObject:heightNumber forKey:threadID];
//    }
//
////    NSArray *heightArray = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? self.homeViewManager.verticalHeights : self.homeViewManager.horizontalHeights;
////    CGFloat preferHeight = tableView.rowHeight;
////    @try {
////        if (indexPath.row < heightArray.count)
////            preferHeight = [[heightArray objectAtIndex:indexPath.row] floatValue];
////    }
////    @catch (NSException *exception) {
////        DLog(@"%@", exception);
////    }
////    
//    return preferHeight;
//}

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
            self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
        }
    }
}


#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    // If image exists
    if ([[czzImageCacheManager sharedInstance] hasImageWithName:imgURL.lastPathComponent]) {
        [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:imgURL.lastPathComponent]];
        return;
    }
    
    // Image not found in local storage, start or stop the image downloader with the image URL
    if ([[czzImageDownloaderManager sharedManager] isImageDownloading:imgURL.lastPathComponent]) {
        [[czzImageDownloaderManager sharedManager] stopDownloadingImage:imgURL.lastPathComponent];
    } else {
        [[czzImageDownloaderManager sharedManager] downloadImageWithURL:imgURL isThumbnail:NO];
    }
}

#pragma mark - czzOnScreenImageManagerViewControllerDelegate

-(void)onScreenImageManagerSelectedImage:(NSString *)path {
    [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:path.lastPathComponent]];
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success) {
        if ([settingCentre userDefShouldAutoOpenImage])
            [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]];
    } else
        DLog(@"img download failed");
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedStopped:(czzImageDownloader *)downloader imageName:(NSString *)imageName {
    if (![downloader isThumbnail])
        [AppDelegate showToast:@"停止下载图片..."];
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedStarted:(czzImageDownloader *)downloader imageName:(NSString *)imageName {
    if (![downloader isThumbnail])
        [AppDelegate showToast:@"开始下载图片..."];
}

#pragma mark - Getters {
- (BOOL)tableViewIsDraggedOverTheBottom {
    return [self tableViewIsDraggedOverTheBottomWithPadding:44];
}

- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding {
    BOOL isOver = NO;
    @try {
        if (self.myTableView.window) {
            NSIndexPath *lastVisibleIndexPath = [self.myTableView indexPathsForVisibleRows].lastObject;
            if (lastVisibleIndexPath.row == self.viewModelManager.threads.count)
            {
                CGPoint contentOffSet = self.myTableView.contentOffset;
                CGRect lastCellRect = [self.myTableView rectForRowAtIndexPath:lastVisibleIndexPath];
                if (lastCellRect.origin.y + lastCellRect.size.height + padding < contentOffSet.y + self.myTableView.frame.size.height) {
                    isOver = YES;
                } else {
                    isOver = NO;
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
        myTableView.estimatedRowHeight = 80;
    }
}

+(instancetype)initWithViewModelManager:(czzHomeViewManager *)viewModelManager {
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
