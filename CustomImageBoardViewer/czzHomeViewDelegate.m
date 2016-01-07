//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeViewDelegate.h"

#import "czzHomeViewManager.h"
#import "czzBlacklist.h"
#import "czzThread.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzSettingsCentre.h"
#import "czzThreadTableView.h"
#import "czzImageViewerUtil.h"
#import "czzThreadViewManager.h"
#import "czzPostViewController.h"
#import "czzNavigationManager.h"

#import "UIApplication+Util.h"
#import "UINavigationController+Util.h"

@interface czzHomeViewDelegate() <czzImageDownloaderManagerDelegate>

@property (strong) czzImageViewerUtil *imageViewerUtil;
@property (nonatomic, readonly) NSIndexPath *lastRowIndexPath;
@property (nonatomic, readonly) BOOL tableViewIsDraggedOverTheBottom;
@property (nonatomic, strong) NSMutableDictionary *cachedHorizontalHeights;
@property (nonatomic, strong) NSMutableDictionary *cachedVerticalHeights;
@property (nonatomic, assign) BOOL bigImageMode;

- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding;
@end

@implementation czzHomeViewDelegate

-(instancetype)init {
    self = [super init];
    if (self) {
        self.imageViewerUtil = [czzImageViewerUtil new];
        self.bigImageMode = [settingCentre userDefShouldUseBigImage];
        [[czzImageDownloaderManager sharedManager] addDelegate:self];
        if ([self isMemberOfClass:[czzHomeViewDelegate class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(settingsChangedNotificationReceived:)
                                                         name:settingsChangedNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)replyToThread:(czzThread *)thread inParentThread:(czzThread *)parentThread{
    czzPostViewController *postViewController = [czzPostViewController new];
    postViewController.forum = self.homeViewManager.forum;
    postViewController.parentThread = parentThread;
    postViewController.replyToThread = thread;
    postViewController.postMode = postViewControllerModeReply;
    [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:postViewController] animated:YES completion:nil];
}

- (void)replyMainThread:(czzThread *)thread {
    czzPostViewController *postViewController = [czzPostViewController new];
    postViewController.forum = self.homeViewManager.forum;
    postViewController.parentThread = thread;
    postViewController.postMode = postViewControllerModeReply;
    [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:postViewController] animated:YES completion:nil];
}

- (void)reportThread:(czzThread *)selectedThread inParentThread:(czzThread *)parentThread {
    czzPostViewController *newPostViewController = [czzPostViewController new];
    newPostViewController.postMode = postViewControllerModeReport;
    [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:newPostViewController] animated:YES completion:nil];
    NSString *reportString = [[settingCentre report_post_placeholder] stringByReplacingOccurrencesOfString:kParentID withString:[NSString stringWithFormat:@"%ld", (long)parentThread.ID]];
    reportString = [reportString stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long)selectedThread.ID]];
    newPostViewController.prefilledString = reportString;
    newPostViewController.title = [NSString stringWithFormat:@"举报:%ld", (long)parentThread.ID];
    //construct a blacklist that to be submitted to my server and pass it to new post view controller
    czzBlacklistEntity *blacklistEntity = [czzBlacklistEntity new];
    blacklistEntity.threadID = selectedThread.ID;
    newPostViewController.blacklistEntity = blacklistEntity;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.myTableView) {
        self.myTableView = (czzThreadTableView*)tableView;
    }
    czzThread *selectedThread;
    @try {
        NSArray *threads = self.homeViewManager.threads;
        if (indexPath.row < threads.count) {
            selectedThread = [self.homeViewManager.threads objectAtIndex:indexPath.row];
            if (![settingCentre shouldAllowOpenBlockedThread]) {
                czzBlacklistEntity *blacklistEntity = [[czzBlacklist sharedInstance] blacklistEntityForThreadID:selectedThread.ID];
                if (blacklistEntity){
                    DDLogDebug(@"blacklisted thread");
                    return;
                }
            }
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
    if (indexPath.row < self.homeViewManager.threads.count)
    {
        //@todo open the selected thread
        czzThreadViewController *threadViewController = [czzThreadViewController new];
        threadViewController.threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:selectedThread andForum:self.homeViewManager.forum];
        [NavigationManager pushViewController:threadViewController animated:YES];
    }
    // If not downloading or processing, load more threads.
    else if (!self.homeViewManager.isDownloading) {
        [self.homeViewManager loadMoreThreads];
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[czzMenuEnabledTableViewCell class]]) {
        // If image should be shown.
        if ([settingCentre userDefShouldDisplayThumbnail] || ![settingCentre shouldDisplayThumbnail]){
            dispatch_async(dispatch_get_main_queue(), ^{
                czzThread *thread = [(czzMenuEnabledTableViewCell *)cell thread];
                // If thread has an image link, and that link is not already been cached.
                if (thread.imgSrc.length) {
                    if (![[czzImageCacheManager sharedInstance] hasThumbnailWithName:thread.imgSrc.lastPathComponent]){
                        [[czzImageDownloaderManager sharedManager] downloadImageWithURL:thread.imgSrc
                                                                            isThumbnail:YES];
                    }
                    // If is on big image mode and the image has not been cacned.
                    if ([settingCentre userDefShouldUseBigImage] && [settingCentre userDefShouldAutoDownloadImage]) {
                        if (![[czzImageCacheManager sharedInstance] hasImageWithName:thread.imgSrc.lastPathComponent]){
                            [[czzImageDownloaderManager sharedManager] downloadImageWithURL:thread.imgSrc
                                                                                isThumbnail:NO];
                        }
                    }
                }
            });
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (UIInterfaceOrientationIsPortrait([UIApplication rootViewController].interfaceOrientation)) {
        [self.cachedVerticalHeights setObject:@(CGRectGetHeight(cell.frame)) forKey:indexPath];
    } else {
        [self.cachedHorizontalHeights setObject:@(CGRectGetHeight(cell.frame)) forKey:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *cachedHeight;
    if (UIInterfaceOrientationIsPortrait([UIApplication rootViewController].interfaceOrientation)) {
        cachedHeight = [self.cachedVerticalHeights objectForKey:indexPath];
    } else {
        cachedHeight = [self.cachedHorizontalHeights objectForKey:indexPath];
    }
    if (cachedHeight) {
        DDLogDebug(@"Cached height for %ldth row: %.1f", (long)indexPath.row, cachedHeight.floatValue);
    }
    return cachedHeight.floatValue ?: UITableViewAutomaticDimension;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([settingCentre userDefShouldShowOnScreenCommand]) {
        [self.myTableView.upDownViewController show];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.homeViewManager.isDownloading && self.homeViewManager.threads.count > 0) {
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
    if (!self.homeViewManager.isDownloading && self.homeViewManager.threads.count > 0) {
        if ([self tableViewIsDraggedOverTheBottomWithPadding:44 * 2]) {
            [self.homeViewManager loadMoreThreads];
            self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
        }
    }
}

#pragma mark - Notification handler

- (void)settingsChangedNotificationReceived:(NSNotification *)notification {
    if (self.bigImageMode != settingCentre.userDefShouldUseBigImage) {
        self.cachedHorizontalHeights = nil;
        self.cachedVerticalHeights = nil;
        self.bigImageMode = settingCentre.userDefShouldUseBigImage;
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

- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread{
    DDLogDebug(@"%s : %@", __PRETTY_FUNCTION__, thread);
    [self replyToThread:thread inParentThread:parentThread];
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

- (void)threadViewCellContentChanged:(czzMenuEnabledTableViewCell *)cell {
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        NSIndexPath *cellIndexPath = [self.myTableView indexPathForCell:cell];
        if (cellIndexPath && [self.myTableView.indexPathsForVisibleRows containsObject:cellIndexPath]) {
            [self.myTableView reloadRowsAtIndexPaths:@[cellIndexPath]
                                    withRowAnimation:UITableViewRowAnimationNone];
        }
    }];
}

#pragma mark - czzOnScreenImageManagerViewControllerDelegate

-(void)onScreenImageManagerSelectedImage:(NSString *)path {
    [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:path.lastPathComponent]];
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success) {
        if (!downloader.isThumbnail && [settingCentre userDefShouldAutoOpenImage] && [self isMemberOfClass:[czzHomeViewDelegate class]])
            [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]];
    } else
        DDLogDebug(@"img download failed");
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

- (NSMutableDictionary *)cachedHorizontalHeights {
    if (!_cachedHorizontalHeights) {
        _cachedHorizontalHeights = [NSMutableDictionary new];
    }
    return _cachedHorizontalHeights;
}

- (NSMutableDictionary *)cachedVerticalHeights {
    if (!_cachedVerticalHeights) {
        _cachedVerticalHeights = [NSMutableDictionary new];
    }
    return _cachedVerticalHeights;
}

- (BOOL)tableViewIsDraggedOverTheBottom {
    return [self tableViewIsDraggedOverTheBottomWithPadding:44];
}

- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding {
    BOOL isOver = NO;
    @try {
        if (self.myTableView.window) {
            NSIndexPath *lastVisibleIndexPath = [self.myTableView indexPathsForVisibleRows].lastObject;
            if (lastVisibleIndexPath.row == self.homeViewManager.threads.count)
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
        DDLogDebug(@"%@", exception);
    }
    return isOver;
}

- (NSIndexPath *)lastRowIndexPath {
    return [NSIndexPath indexPathForRow:self.homeViewManager.threads.count inSection:0];
}

#pragma marl - Setters
- (void)setMyTableView:(czzThreadTableView *)myTableView {
    _myTableView = myTableView;
    if (myTableView) {
        myTableView.estimatedRowHeight = 80;
        myTableView.rowHeight = UITableViewAutomaticDimension;
    }
}

+(instancetype)initWithViewManager:(czzHomeViewManager *)viewManager andTableView:(czzThreadTableView *)tableView {
    czzHomeViewDelegate *sharedDelegate = [czzHomeViewDelegate sharedInstance];
    sharedDelegate.homeViewManager = viewManager;
    sharedDelegate.myTableView = tableView;
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
