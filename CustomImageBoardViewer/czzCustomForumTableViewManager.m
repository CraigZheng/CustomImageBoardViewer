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
#import "czzForumsViewController.h" 

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) {
        czzForum *forum = [[czzForumManager sharedManager].customForums objectAtIndex:indexPath.row];
        //POST a local notification to inform other view controllers that a new forum is picked
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setObject:forum forKey:kPickedForum];
        [[NSNotificationCenter defaultCenter] postNotificationName:kForumPickedNotification object:self userInfo:userInfo];
        [[SlideNavigationController sharedInstance] closeMenuWithCompletion:nil];
    } else {
        [NavigationManager.delegate performSegueWithIdentifier:@"showAddForum" sender:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    // If currently is the last row, show the management cell.
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"customForumManagerCell" forIndexPath:indexPath];
        cell.textLabel.text = @"管理自定义板块";
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"forum_cell_identifier" forIndexPath:indexPath];
        czzForum *forum = [czzForumManager sharedManager].customForums[indexPath.row];
        UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
        titleLabel.textColor = [settingCentre contentTextColour];
        [titleLabel setText:[forum name]];
    }
    return cell;
}

@end
