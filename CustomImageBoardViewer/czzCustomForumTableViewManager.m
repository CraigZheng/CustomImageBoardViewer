//
//  czzCustomForumTableViewManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 24/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzCustomForumTableViewManager.h"

#import "czzAddForumTableViewController.h"
#import "czzForum.h"
#import "czzForumManager.h"
#import "czzSettingsCentre.h"
#import "czzForumsViewController.h"

#import "SlideNavigationController.h"

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
        czzAddForumTableViewController *addForumViewController = [[czzAddForumTableViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addForumViewController];
        navigationController.definesPresentationContext = YES;
        navigationController.toolbarHidden = NO;
        [NavigationManager.delegate presentViewController:navigationController animated:YES completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    // If currently is the last row, show the management cell.
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"customForumManagerCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"customForumManagerCell"];
            cell.textLabel.font = [UIFont systemFontOfSize:16];
        }
        cell.textLabel.text = @"管理自定义板块";
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"forum_cell_identifier"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"forum_cell_identifier"];
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.backgroundColor = [UIColor clearColor];
        }
        czzForum *forum = [czzForumManager sharedManager].customForums[indexPath.row];
        UILabel *titleLabel = [cell textLabel];
        [titleLabel setText:[forum name]];
    }
    cell.textLabel.textColor = [settingCentre contentTextColour];
    cell.backgroundColor = [settingCentre viewBackgroundColour];
    return cell;
}

@end
