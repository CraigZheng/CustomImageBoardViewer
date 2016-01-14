//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeTableViewManager.h"

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
#import "czzThreadViewCommandStatusCellViewController.h"
#import "czzThreadTableViewCommandCellTableViewCell.h"

#import "UIApplication+Util.h"
#import "UINavigationController+Util.h"
#import "czzMenuEnabledTableViewCell.h"

@interface czzHomeTableViewManager() <czzImageDownloaderManagerDelegate>

@property (strong) czzImageViewerUtil *imageViewerUtil;
@property (nonatomic, readonly) NSIndexPath *lastRowIndexPath;
@property (nonatomic, readonly) BOOL tableViewIsDraggedOverTheBottom;
@property (nonatomic, assign) BOOL bigImageMode;
@property (nonatomic, strong) czzMenuEnabledTableViewCell *sizingCell;

- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding;

@end

@implementation czzHomeTableViewManager

-(instancetype)init {
    self = [super init];
    if (self) {
        self.imageViewerUtil = [czzImageViewerUtil new];
        self.bigImageMode = [settingCentre userDefShouldUseBigImage];
        [[czzImageDownloaderManager sharedManager] addDelegate:self];
        if ([self isMemberOfClass:[czzHomeTableViewManager class]]) {
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
    if (!self.homeTableView) {
        self.homeTableView = (czzThreadTableView*)tableView;
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


#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.homeViewManager.threads.count > 0)
        return self.homeViewManager.threads.count + 1;
    return self.homeViewManager.threads.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == self.homeViewManager.threads.count){
        //Last row
        NSString *lastCellIdentifier = THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER;
        czzThreadTableViewCommandCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lastCellIdentifier forIndexPath:indexPath];
        cell.commandStatusViewController = self.homeTableView.lastCellCommandViewController;
        cell.commandStatusViewController.homeViewManager = self.homeViewManager;
        self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
        if (self.homeViewManager.pageNumber == self.homeViewManager.totalPages) {
            self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeNoMore;
        }
        if (self.homeViewManager.isDownloading) {
            self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
        }
        
        cell.backgroundColor = [settingCentre viewBackgroundColour];
        return cell;
    }
    
    NSString *cell_identifier = THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [self.homeViewManager.threads objectAtIndex:indexPath.row];
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        cell.delegate = self;
        cell.shouldHighlight = NO;
        cell.myIndexPath = indexPath;
        cell.nightyMode = [settingCentre userDefNightyMode];
        cell.bigImageMode = [settingCentre userDefShouldUseBigImage];
        cell.cellType = threadViewCellTypeHome;
        cell.parentThread = thread;
        cell.thread = thread;
        if ([self isMemberOfClass:[czzHomeTableViewManager class]]) {
            [cell renderContent];
        }
    }
    return cell;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([settingCentre userDefShouldShowOnScreenCommand]) {
        [self.homeTableView.upDownViewController show];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.homeViewManager.isDownloading && self.homeViewManager.threads.count > 0) {
        if (self.tableViewIsDraggedOverTheBottom) {
            if ([self tableViewIsDraggedOverTheBottomWithPadding:44 * 2]) {
                self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore;
            } else {
                if (self.homeTableView.lastCellType != czzThreadViewCommandStatusCellViewTypeLoadMore) {
                    self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
                }
            }
        }
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.homeViewManager.isDownloading && self.homeViewManager.threads.count > 0) {
        if ([self tableViewIsDraggedOverTheBottomWithPadding:44 * 2]) {
            [self.homeViewManager loadMoreThreads];
            self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
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
    [self.cachedHorizontalHeights removeObjectForKey:@(cell.thread.ID)];
    [self.cachedVerticalHeights removeObjectForKey:@(cell.thread.ID)];
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        NSIndexPath *cellIndexPath = [self.homeTableView indexPathForCell:cell];
        if (cellIndexPath && [self.homeTableView.indexPathsForVisibleRows containsObject:cellIndexPath]) {
            [self.homeTableView reloadRowsAtIndexPaths:@[cellIndexPath]
                                    withRowAnimation:UITableViewRowAnimationNone];
        }
    }];
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success) {
        if (!downloader.isThumbnail && [settingCentre userDefShouldAutoOpenImage] && [self isMemberOfClass:[czzHomeTableViewManager class]])
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

#pragma mark - Getters 

- (czzMenuEnabledTableViewCell *)sizingCell {
    if (!_sizingCell) {
        _sizingCell = [self.homeTableView dequeueReusableCellWithIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    }
    return _sizingCell;
}

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
        if (self.homeTableView.window) {
            NSIndexPath *lastVisibleIndexPath = [self.homeTableView indexPathsForVisibleRows].lastObject;
            if (lastVisibleIndexPath.row == self.homeViewManager.threads.count)
            {
                CGPoint contentOffSet = self.homeTableView.contentOffset;
                CGRect lastCellRect = [self.homeTableView rectForRowAtIndexPath:lastVisibleIndexPath];
                if (lastCellRect.origin.y + lastCellRect.size.height + padding < contentOffSet.y + self.homeTableView.frame.size.height) {
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
- (void)setHomeTableView:(czzThreadTableView *)homeTableView {
    _homeTableView = homeTableView;
    if (homeTableView) {
        homeTableView.estimatedRowHeight = 80;
        homeTableView.rowHeight = UITableViewAutomaticDimension;
    }
}

@end
