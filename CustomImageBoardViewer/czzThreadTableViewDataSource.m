//
//  czzThreadTableViewDataSource.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableViewDataSource.h"

#import "czzThreadList.h"
#import "czzSettingsCentre.h"

#import "czzMenuEnabledTableViewCell.h"

@interface czzThreadTableViewDataSource () <czzMenuEnabledTableViewCellProtocol>
@property (weak, nonatomic) UITableView *myTableView;
@end

@implementation czzThreadTableViewDataSource
@synthesize myTableView;
@synthesize threadList;

-(void)reset {
    
}

#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (threadList.threads.count > 0)
        return threadList.threads.count + 1;
    return threadList.threads.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!myTableView) {
        self.myTableView = tableView;
    }
    
    if (indexPath.row == threadList.threads.count){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (threadList.isDownloading || threadList.isProcessing) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        }
        cell.backgroundColor = [settingCentre viewBackgroundColour];
        return cell;
    }
    
    NSString *cell_identifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [threadList.threads objectAtIndex:indexPath.row];
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        cell.delegate = self;
        cell.shouldHighlight = NO;
        cell.shouldAllowClickOnImage = ![settingCentre userDefShouldUseBigImage];
        cell.parentThread = thread;
        cell.myIndexPath = indexPath;
        cell.myThread = thread;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    DLog(@"%s", __func__);
//    selectedIndex = indexPath;
//    @try {
//        if (indexPath.row < threads.count) {
//            selectedThread = [threads objectAtIndex:selectedIndex.row];
//            if (!settingsCentre.shouldAllowOpenBlockedThread) {
//                czzBlacklistEntity *blacklistEntity = [[czzBlacklist sharedInstance] blacklistEntityForThreadID:selectedThread.ID];
//                if (blacklistEntity){
//                    DLog(@"blacklisted thread");
//                    return;
//                }
//            }
//        }
//    }
//    @catch (NSException *exception) {
//        
//    }
//    if (selectedIndex.row < threads.count)
//        [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];
//    else {
//        [threadList loadMoreThreads];
//        [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
}


#pragma mark - UIScrollVIew delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    threadList.currentOffSet = scrollView.contentOffset;
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
    if (indexPath.row >= threadList.threads.count)
        return tableView.rowHeight;
    
    NSArray *heightArray = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].keyWindow.rootViewController.interfaceOrientation) ? threadList.verticalHeights : threadList.horizontalHeights;
    CGFloat preferHeight = tableView.rowHeight;
    @try {
        preferHeight = [[heightArray objectAtIndex:indexPath.row] floatValue];
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    return preferHeight;
}

#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
//    [self openImageWithPath:imgURL];
}

-(void)imageDownloadedForIndexPath:(NSIndexPath *)index filePath:(NSString *)path isThumbnail:(BOOL)isThumbnail {
    if (isThumbnail) {
        @try {
            [myTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
    }
}


#pragma mark - setters
-(void)setMyTableView:(UITableView *)incomingTableView {
    myTableView = incomingTableView;
    if (myTableView) {
        [myTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
        [myTableView registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    }
}

+(instancetype)initWithThreadList:(czzThreadList *)threadList {
    czzThreadTableViewDataSource *dataSource = [czzThreadTableViewDataSource new];
    dataSource.threadList = threadList;
    return dataSource;
}
@end
