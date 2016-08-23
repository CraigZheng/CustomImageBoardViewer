//
//  czzCustomForumTableViewManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 24/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzCustomForumTableViewManager.h"

#import "czzForum.h"
#import "czzForumManager.h"
#import "czzSettingsCentre.h"

@implementation czzCustomForumTableViewManager

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return [czzForumManager sharedManager].customForums.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"forum_cell_identifier" forIndexPath:indexPath];
    // If currently is the last row, show the management cell.
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"customForumManagerCell" forIndexPath:indexPath];
        cell.textLabel.text = @"管理自定义板块";
    } else {
        czzForum *forum = [czzForumManager sharedManager].customForums[indexPath.row];
        UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
        titleLabel.textColor = [settingCentre contentTextColour];
        [titleLabel setText:[forum name]];
    }
    return cell;
}

@end
