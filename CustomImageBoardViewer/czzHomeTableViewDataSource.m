//
//  czzThreadTableViewDataSource.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeTableViewDataSource.h"

#import "czzHomeViewModelManager.h"
#import "czzSettingsCentre.h"
#import "czzThreadTableViewCommandCellTableViewCell.h"
#import "czzImageViewerUtil.h"

@interface czzHomeTableViewDataSource ()

@end

@implementation czzHomeTableViewDataSource
@synthesize myTableView;
@synthesize viewModelManager;

-(void)reset {
    //TODO reset
}

#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (viewModelManager.threads.count > 0)
        return viewModelManager.threads.count + 1;
    return viewModelManager.threads.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!myTableView) {
        self.myTableView = (czzThreadTableView*)tableView;
    }
    
    if (indexPath.row == viewModelManager.threads.count){
        //Last row
        NSString *lastCellIdentifier = THREAD_TABLE_VIEW_CELL_LOAD_MORE_CELL_IDENTIFIER;
        if (self.myTableView.lastCellType == czzThreadTableViewLastCommandCellTypeReleaseToLoadMore) {
            lastCellIdentifier = THREAD_TABLE_VIEW_CELL_RELEASE_TO_LOAD_MORE_CELL_IDENTIFIER;
        } else if (self.viewModelManager.pageNumber == self.viewModelManager.totalPages) {
            lastCellIdentifier = THREAD_TABLE_VIEW_CELL_NO_MORE_CELL_IDENTIFIER;
        }
        if (viewModelManager.isDownloading || viewModelManager.isProcessing) {
            lastCellIdentifier = THREAD_TABLE_VIEW_CELL_LOADING_CELL_IDENTIFIER;
        }
        
        czzThreadTableViewCommandCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lastCellIdentifier forIndexPath:indexPath];
        cell.backgroundColor = [settingCentre viewBackgroundColour];
        [cell.activityIndicator startAnimating];
        return cell;
    }
    
    NSString *cell_identifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [viewModelManager.threads objectAtIndex:indexPath.row];
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        cell.delegate = self.tableViewDelegate;
        cell.shouldHighlight = NO;
        cell.shouldAllowClickOnImage = ![settingCentre userDefShouldUseBigImage];
        cell.parentThread = thread;
        cell.myIndexPath = indexPath;
        cell.myThread = thread;
    }
    return cell;
}

#pragma mark - setters
-(void)setMyTableView:(czzThreadTableView *)incomingTableView {
    myTableView = incomingTableView;

}

+(instancetype)initWithViewModelManager:(czzHomeViewModelManager *)viewModelManager {
    czzHomeTableViewDataSource *dataSource = [czzHomeTableViewDataSource new];
    dataSource.viewModelManager = viewModelManager;
    return dataSource;
}
@end
