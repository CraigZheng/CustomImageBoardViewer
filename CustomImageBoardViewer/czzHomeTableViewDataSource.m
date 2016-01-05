//
//  czzThreadTableViewDataSource.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeTableViewDataSource.h"

#import "czzHomeViewManager.h"
#import "czzSettingsCentre.h"
#import "czzThreadTableViewCommandCellTableViewCell.h"
#import "czzImageViewerUtil.h"
#import "czzMenuEnabledTableViewCell.h"

@interface czzHomeTableViewDataSource ()

@end

@implementation czzHomeTableViewDataSource
@synthesize myTableView = _myTableView;
@synthesize homeViewManager;

-(void)reset {
    //TODO reset
}

#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (homeViewManager.threads.count > 0)
        return homeViewManager.threads.count + 1;
    return homeViewManager.threads.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == homeViewManager.threads.count){
        //Last row
        NSString *lastCellIdentifier = THREAD_TABLEVIEW_COMMAND_CELL_IDENTIFIER;
        czzThreadTableViewCommandCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lastCellIdentifier forIndexPath:indexPath];
        cell.commandStatusViewController = self.myTableView.lastCellCommandViewController;
        cell.commandStatusViewController.homeViewManager = self.homeViewManager;
        self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
        if (self.homeViewManager.pageNumber == self.homeViewManager.totalPages) {
            self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeNoMore;
        }
        if (homeViewManager.isDownloading) {
            self.myTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoading;
        }
        
        cell.backgroundColor = [settingCentre viewBackgroundColour];
        return cell;
    }
    
    NSString *cell_identifier = THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [homeViewManager.threads objectAtIndex:indexPath.row];
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



+(instancetype)initWithViewManager:(czzHomeViewManager *)viewManager andTableView:(czzThreadTableView *)tableView {
    czzHomeTableViewDataSource *dataSource = [czzHomeTableViewDataSource new];
    dataSource.homeViewManager = viewManager;
    dataSource.myTableView = tableView;
    return dataSource;
}
@end
