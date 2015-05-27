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

@interface czzHomeTableViewDataSource ()

@end

@implementation czzHomeTableViewDataSource
@synthesize myTableView;
@synthesize viewModelManager;

-(void)reset {
    
}

#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (viewModelManager.threads.count > 0)
        return viewModelManager.threads.count + 1;
    return viewModelManager.threads.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!myTableView) {
        self.myTableView = tableView;
    }
    
    if (indexPath.row == viewModelManager.threads.count){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (viewModelManager.isDownloading || viewModelManager.isProcessing) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        }
        cell.backgroundColor = [settingCentre viewBackgroundColour];
        return cell;
    }
    
    NSString *cell_identifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    czzThread *thread = [viewModelManager.threads objectAtIndex:indexPath.row];
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

+(instancetype)initWithViewModelManager:(czzHomeViewModelManager *)viewModelManager {
    czzHomeTableViewDataSource *dataSource = [czzHomeTableViewDataSource new];
    dataSource.viewModelManager = viewModelManager;
    return dataSource;
}
@end
