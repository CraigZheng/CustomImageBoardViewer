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
#import "czzReplyUtil.h"
#import "UIApplication+Util.h"
#import "UINavigationController+Util.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzMarkerManager.h"
#import "czzBigImageModeTableViewCell.h"
#import <ImageIO/ImageIO.h>

#import "CustomImageBoardViewer-Swift.h"

@interface czzHomeTableViewManager() <czzImageDownloaderManagerDelegate, UIDataSourceModelAssociation>

@property (strong) czzImageViewerUtil *imageViewerUtil;
@property (nonatomic, readonly) NSIndexPath *lastRowIndexPath;
@property (nonatomic, readonly) BOOL tableViewIsDraggedOverTheBottom;
@property (nonatomic, readonly) BOOL bigImageMode;
@property (nonatomic, strong) czzMenuEnabledTableViewCell *sizingCell;
@property (nonatomic, strong) NSMutableOrderedSet *pendingBulkUpdateIndexes;
@property (nonatomic, strong) NSTimer *bulkUpdateTimer;

- (BOOL)tableViewIsDraggedOverTheBottomWithPadding:(CGFloat)padding;

@end

@implementation czzHomeTableViewManager

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
        UIMenuItem *reportMenuItem = [[UIMenuItem alloc] initWithTitle:@"举报"
                                                               action:NSSelectorFromString(@"menuActionReport:")];
        //    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
        [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, reportMenuItem, /*searchMenuItem,*/ openMenuItem]];
        [[UIMenuController sharedMenuController] update];
        
        self.imageViewerUtil = [czzImageViewerUtil new];
        self.pendingBulkUpdateIndexes = [NSMutableOrderedSet new];
        [[czzImageDownloaderManager sharedManager] addDelegate:self];
    }
    return self;
}

- (void)reloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.homeTableView) {
            [self.homeTableView reloadData];
        }
    });
}

- (void)bulkUpdateRows:(id)sender {
    NSMutableArray *pendingIndexes = [NSMutableArray new];
    // Find all the pending indexes that are still visible.
    for (NSIndexPath *cellIndexPath in self.pendingBulkUpdateIndexes) {
        if ([self.homeTableView.indexPathsForVisibleRows containsObject:cellIndexPath]) {
            [pendingIndexes addObject:cellIndexPath];
        }
    }
    // Update all the visible pending indexes.
    if (pendingIndexes.count) {
        [self.homeTableView reloadRowsAtIndexPaths:pendingIndexes
                                  withRowAnimation:UITableViewRowAnimationNone];
    }
    // Clear pending indexes.
    [self.pendingBulkUpdateIndexes removeAllObjects];
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.homeViewManager.threads.count) {
        return YES;
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
}

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
        threadViewController.thread = selectedThread;
        [NavigationManager pushViewController:threadViewController animated:YES];
    }
    // If not downloading or processing, load more threads.
    else if (!self.homeViewManager.isDownloading) {
        [self.homeViewManager loadMoreThreads];
        self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = UITableViewAutomaticDimension;
    BOOL quickScrolling = [(czzThreadTableView *)tableView quickScrolling];
    if (quickScrolling) {
        // If quick scrolling, return the estimated height instead.
        height = [self tableView:tableView
estimatedHeightForRowAtIndexPath:indexPath];
    }
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat estimatedHeight = 44.0;
    if (indexPath.row < self.homeViewManager.threads.count) {
        czzThread *thread = self.homeViewManager.threads[indexPath.row];
        // Estimated height based on the content.
        @try {
            estimatedHeight = [[[NSAttributedString alloc] initWithString:thread.content.string.length ? thread.content.string : @""
                                                               attributes:@{NSFontAttributeName: settingCentre.contentFont}] boundingRectWithSize:CGSizeMake(CGRectGetWidth(tableView.frame), MAXFLOAT)
                               options:NSStringDrawingUsesLineFragmentOrigin
                               context:nil].size.height + 44;
        } @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
        // Calculate an estimated height based on if an image is available.
        if (thread.imgSrc.length && settingCentre.shouldDisplayImage) {
            // If big image mode and has the image, add 75% of the shortest edge to the estimated height.
            if (self.bigImageMode &&
                [[czzImageCacheManager sharedInstance] hasImageWithName:thread.imgSrc.lastPathComponent]) {
                CGSize imageSize = [self getImageSizeWithPath:[[czzImageCacheManager sharedInstance] pathForImageWithName:thread.imgSrc.lastPathComponent]];
                CGFloat bigImageHeightLimit = CGRectGetHeight(tableView.frame) * 0.75;
                // If the actual image height is smaller than big image height limit, use the actual height.
                if (!CGSizeEqualToSize(CGSizeZero, imageSize) && imageSize.height < bigImageHeightLimit) {
                    estimatedHeight += imageSize.height;
                } else {
                    estimatedHeight += bigImageHeightLimit;
                }
            } else {
                CGSize previewImageSize = [self getImageSizeWithPath:[[czzImageCacheManager sharedInstance] pathForThumbnailWithName:thread.imgSrc.lastPathComponent]];
                if (!CGSizeEqualToSize(previewImageSize, CGSizeZero)) {
                    estimatedHeight += previewImageSize.height < 150 ? previewImageSize.height : 150;
                } else {
                    // Add the fixed image view size to the estimated height.
                    estimatedHeight += 36;
                }
            }
        }
    }
    return estimatedHeight;
}

// Copied from http://stackoverflow.com/questions/4169677/accessing-uiimage-properties-without-loading-in-memory-the-image/4170099#4170099
- (CGSize)getImageSizeWithPath:(NSURL *)imageURL {
    CGImageSourceRef imageSource = imageURL != nil ?
    CGImageSourceCreateWithURL((CFURLRef)imageURL, NULL) : NULL;
    if (imageSource == NULL) {
        // Error loading image
        return CGSizeZero;
    }
    
    CGFloat width = 0.0f, height = 0.0f;
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        
    if (imageProperties != NULL) {
        
        CFNumberRef widthNum  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
        if (widthNum != NULL) {
            CFNumberGetValue(widthNum, kCFNumberCGFloatType, &width);
        }
        
        CFNumberRef heightNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
        if (heightNum != NULL) {
            CFNumberGetValue(heightNum, kCFNumberCGFloatType, &height);
        }
        
        // Check orientation and flip size if required
        CFNumberRef orientationNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
        if (orientationNum != NULL) {
            int orientation;
            CFNumberGetValue(orientationNum, kCFNumberIntType, &orientation);
            if (orientation > 4) {
                CGFloat temp = width;
                width = height;
                height = temp;
            }
        }
    }
    
    return CGSizeMake(width, height);
}

#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.homeViewManager.threads.count > 0)
        return self.homeViewManager.threads.count + 1;
    return self.homeViewManager.threads.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == self.homeViewManager.threads.count) {
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
    
    NSString *cell_identifier = settingCentre.userDefShouldUseBigImage ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [self.homeViewManager.threads objectAtIndex:indexPath.row];
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        cell.delegate = self;
        if ([[czzMarkerManager sharedInstance] isHighlighted:thread.UID]) {
            cell.highlightColour = [[czzMarkerManager sharedInstance] highlightColourForUID:thread.UID];
            cell.nickname = [[czzMarkerManager sharedInstance] nicknameForUID:thread.UID];
        } else {
            cell.highlightColour = nil;
            cell.nickname = nil;
        }
        if ([[czzMarkerManager sharedInstance] isUIDBlocked:thread.UID]) {
            cell.shouldBlock = YES;
            cell.allowImage = NO;
            cell.highlightColour = [UIColor lightGrayColor];
        } else {
            cell.shouldBlock = NO;
            cell.allowImage = [settingCentre userDefShouldDisplayThumbnail];
        }
        cell.myIndexPath = indexPath;
        cell.nightyMode = [settingCentre userDefNightyMode];
        cell.bigImageMode = [settingCentre userDefShouldUseBigImage];
        cell.cellType = threadViewCellTypeHome;
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
    // If current the view manager reports its being downloaded, don't do anything.
    if (!self.homeViewManager.isDownloading) {
        // If dragged over the threshold, set to "release to load more" cell.
        if (self.tableViewIsDraggedOverTheBottom &&
            self.homeViewManager.pageNumber < self.homeViewManager.totalPages) {
            self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore;
        } else {
            self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
        }
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // If user released while the scrollView is dragged up over the threshold, and view manager still has unloaded page, reload the view manager.
    if (!self.homeViewManager.isDownloading &&
        self.homeTableView.lastCellType == czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore &&
        self.homeViewManager.pageNumber < self.homeViewManager.totalPages) {
        [self.homeViewManager loadMoreThreads];
        self.homeTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
    }
}

#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(id)sender {
    UITableViewCell *cell;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *)sender;
        // Get indexPath, then the corresponding threads from it.
        NSIndexPath *indexPath = [self.homeTableView indexPathForCell:cell];
        if (indexPath && indexPath.row < self.homeViewManager.threads.count) {
            NSString *imgURL = [self.homeViewManager.threads[indexPath.row] imgSrc];
            if (imgURL.length) {
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
        }
    }
}

- (void)userTapInQuotedText:(NSString *)text {
    // Text cannot be parsed to an integer, return...
    text = [text componentsSeparatedByString:@"/"].lastObject;
    NSInteger threadID = text.integerValue;
    if (!threadID) {
        return;
    }
    
    // Thread not found in the downloaded thread, get it from server instead.
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"正在下载: %ld", (long)text.integerValue]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        czzThread * thread = [[czzThread alloc] initWithThreadID:text.integerValue];
        // After return, run the remaining codes in main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (thread) {
                [self.homeViewManager showContentWithThread:thread];
            } else {
                [MessagePopup showMessagePopupWithTitle:nil
                                                message:[NSString stringWithFormat:@"找不到引用串：%ld", (long)thread.ID]
                                                 layout:MessagePopupLayoutCardView
                                                  theme:MessagePopupThemeError
                                               position:MessagePopupPresentationStyleTop
                                            buttonTitle:nil
                                    buttonActionHandler:nil];
            }
        });
    });
}

- (void)userWantsToReply:(czzThread *)thread inParentThread:(czzThread *)parentThread{
    DDLogDebug(@"%s : %@", __PRETTY_FUNCTION__, thread);
    [czzReplyUtil replyToThread:thread inParentThread:parentThread];
}

- (void)userWantsToReport:(czzThread *)thread inParentThread:(czzThread *)parentThread {
    [czzReplyUtil reportThread:thread inParentThread:parentThread];
}

- (void)userWantsToHighlightUser:(NSString *)UID {
    [self.homeViewManager highlightUID:UID];
}

- (void)userWantsToBlockUser:(NSString *)UID {
    [self.homeViewManager blockUID:UID];
}

- (void)userWantsToSearch:(czzThread *)thread {
    DDLogDebug(@"%s : NOT IMPLEMENTED", __PRETTY_FUNCTION__);
}

- (void)threadViewCellContentChanged:(czzMenuEnabledTableViewCell *)cell {
    // Group the incoming calls within next set period of time to update in a batch.
    if (!self.bulkUpdateTimer.isValid) {
        self.bulkUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.4
                                                                target:self
                                                              selector:@selector(bulkUpdateRows:)
                                                              userInfo:nil
                                                               repeats:NO];
    }
    NSIndexPath *cellIndexPath = [self.homeTableView indexPathForCell:cell];
    if (cellIndexPath) {
        [self.pendingBulkUpdateIndexes addObject:cellIndexPath];
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    if (success) {
        // If: not thumbnail, self is czzHomeTableViewManager, should auto open image.
        if (!downloader.isThumbnail
            && [self isMemberOfClass:[czzHomeTableViewManager class]]) {
            if ([settingCentre userDefShouldAutoOpenImage]) {
                // If user is in big image mode, don't auto open image when auto download is on.
                if ([settingCentre userDefShouldUseBigImage]) {
                    if (![settingCentre userDefShouldAutoDownloadImage]) {
                        [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]];
                    }
                } else {
                    [self.imageViewerUtil showPhoto:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]];
                }
            } else if (!settingCentre.userDefShouldUseBigImage && !settingCentre.shouldShowImageManagerButton) {
                // When not automatically openning image, not big image mode and not showing image manager button, show a toast message to user instead.
                [AppDelegate showToast:@"图片下载完毕"];
            }
        }
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

- (BOOL)bigImageMode {
    return [settingCentre userDefShouldUseBigImage];
}

#pragma mark - Setters
- (void)setHomeTableView:(czzThreadTableView *)homeTableView {
    _homeTableView = homeTableView;
    if (homeTableView) {
        homeTableView.estimatedRowHeight = 80;
        homeTableView.rowHeight = UITableViewAutomaticDimension;
    }
}

#pragma mark - UIDataSourceModelAssociation

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)idx inView:(UIView *)view {
    if (idx.row < self.homeViewManager.threads.count) {
        // Return thread ID.
        return [NSString stringWithFormat:@"%ld", (long)[self.homeViewManager.threads[idx.row] ID]];
    } else {
        // Last row.
        return @"lastRow";
    }
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view {
    if ([identifier isEqualToString:@"lastRow"]) {
        // Return last row.
        return [NSIndexPath indexPathForRow:0 inSection:self.homeViewManager.threads.count];
    } else {
        NSInteger identifierInteger = [identifier integerValue];
        for (czzThread * thread in self.homeViewManager.threads) {
            if (thread.ID == identifierInteger) {
                return [NSIndexPath indexPathForRow:0 inSection:[self.homeViewManager.threads indexOfObject:thread]];
            }
        }
    }
    // Failed to return anything.
    return nil;
}

@end
