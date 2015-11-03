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
@property czzThreadViewManager *threadViewManager;
@end

@implementation czzThreadTableViewDataSource

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowNumber = [super tableView:tableView numberOfRowsInSection:section];
    return rowNumber;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    // If within the range of threads, is a thread view cell, otherwise is a command cell.
    if (indexPath.row < self.threadViewManager.threads.count) {
        czzThread *thread = [self.threadViewManager.threads objectAtIndex:indexPath.row];
        // Thread view cell
        if (cell && [cell isKindOfClass:[czzMenuEnabledTableViewCell class]]){
            czzMenuEnabledTableViewCell *threadViewCell = (czzMenuEnabledTableViewCell*)cell;
            threadViewCell.delegate = self.tableViewDelegate;
            threadViewCell.shouldHighlight = YES;
            threadViewCell.selectedUserToHighlight = self.threadViewManager.selectedUserToHighlight;
            threadViewCell.parentThread = self.threadViewManager.parentThread;
            threadViewCell.myThread = thread;
            threadViewCell.myIndexPath = indexPath;
            threadViewCell.shouldAllowClickOnImage = YES;
        }
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

#pragma mark - Accessors

-(czzThreadViewManager *)threadViewManager {
    return (id)[super homeViewManager];
}

-(void)setThreadViewManager:(czzThreadViewManager *)threadViewManager {
    [super setHomeViewManager:threadViewManager];
}

@end
