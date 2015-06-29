//
//  czzThreadTableViewDataSource.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableViewDataSource.h"
#import "czzThreadTableViewCommandCellTableViewCell.h"

@interface czzThreadTableViewDataSource ()
@property czzThreadViewModelManager *viewModelManager;
@end

@implementation czzThreadTableViewDataSource
@dynamic viewModelManager;

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.viewModelManager.threads.count > 0)
        return self.viewModelManager.threads.count + 1;
    return self.viewModelManager.threads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.myTableView) {
        self.myTableView = (czzThreadTableView*)tableView;
    }
    NSString *cell_identifier = [settingCentre userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    if (indexPath.row == self.viewModelManager.threads.count){
        UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (self.viewModelManager.isDownloading || self.viewModelManager.isProcessing) {
            cell = [tableView dequeueReusableCellWithIdentifier:THREAD_TABLE_VIEW_CELL_LOADING_CELL_IDENTIFIER];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        } else if (self.viewModelManager.parentThread.responseCount > [settingCentre response_per_page] && (self.viewModelManager.pageNumber * [settingCentre response_per_page] + self.viewModelManager.threads.count % [settingCentre response_per_page] - 1) < self.viewModelManager.parentThread.responseCount){
            
            cell = [tableView dequeueReusableCellWithIdentifier:THREAD_TABLE_VIEW_CELL_LOAD_MORE_CELL_IDENTIFIER];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:THREAD_TABLE_VIEW_CELL_NO_MORE_CELL_IDENTIFIER];
        }
        cell.backgroundColor = [settingCentre viewBackgroundColour];
        return cell;
    }
    czzThread *thread = [self.viewModelManager.threads objectAtIndex:indexPath.row];
    
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    // Configure the cell...
    if (cell){
        cell.delegate = self;
        cell.shouldHighlightSelectedUser = self.shouldHighlightSelectedUser;
        cell.parentThread = self.viewModelManager.parentThread;
        cell.myThread = thread;
        cell.myIndexPath = indexPath;
    }
    return cell;
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

+(instancetype)initWithViewModelManager:(czzThreadViewModelManager *)viewModelManager {
    czzThreadTableViewDataSource *threadDataSource = [czzThreadTableViewDataSource new];
    threadDataSource.viewModelManager = viewModelManager;
    return threadDataSource;
}
@end
