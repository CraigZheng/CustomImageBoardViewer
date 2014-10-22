//
//  czzSettingsViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzSettingsViewController.h"
#import "Toast+UIView.h"
#import "czzImageCentre.h"
#import "czzAppDelegate.h"
#import "czzThreadCacheManager.h"
#import "czzHomeViewController.h"
#import "czzSettingsCentre.h"

#import "DartCrowdSourcingLib/DartCrowdSourcingConstants.h"

@interface czzSettingsViewController ()<UIAlertViewDelegate, UIActionSheetDelegate>
@property NSMutableArray *commands;
@property NSMutableArray *regularCommands;
@property NSMutableArray *switchCommands;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzSettingsViewController
@synthesize settingsTableView;
@synthesize commands, regularCommands, switchCommands;
@synthesize settingsCentre;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    settingsCentre = [czzSettingsCentre sharedInstance];
    commands = [NSMutableArray new];
    regularCommands = [NSMutableArray new];
    switchCommands = [NSMutableArray new];
    [self prepareCommands];
    self.settingsTableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = settingsCentre.viewBackgroundColour;
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0)
        return switchCommands.count;
    else
        return regularCommands.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0)
        return @"软件设置";
    else
        return @"工具";
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"command_cell_identifier"];
    if (indexPath.section == 0){
        cell = [tableView dequeueReusableCellWithIdentifier:@"switch_cell_identifier"];
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:3];
        UISwitch *commandSwitch = (UISwitch*)[cell viewWithTag:4];
        commandLabel.textColor = settingsCentre.contentTextColour;
        NSString *command = [switchCommands objectAtIndex:indexPath.row];
        commandLabel.text = command;

        [commandSwitch addTarget:self action:@selector(switchDidChanged:) forControlEvents:UIControlEventValueChanged];
        //set value for switch
        if ([command isEqualToString:@"显示图片"]){
            BOOL shouldLoadImages = settingsCentre.userDefShouldDisplayThumbnail;
            [commandSwitch setOn:shouldLoadImages];
        }
        else if ([command isEqualToString:@"显示快速滑动按钮"]) {
            BOOL sbouldShowOnScreenCommand = settingsCentre.userDefShouldShowOnScreenCommand;
            [commandSwitch setOn:sbouldShowOnScreenCommand];
        }
        else if ([command isEqualToString:@"图片下载完毕自动打开"]){
             BOOL shouldAutoOpen = settingsCentre.userDefShouldAutoOpenImage;
            [commandSwitch setOn:shouldAutoOpen];

         } else if ([command isEqualToString:@"开启帖子缓存"]){
             BOOL shouldCache = settingsCentre.userDefShouldCacheData;
             [commandSwitch setOn:shouldCache];
         } else if ([command isEqualToString:@"高亮楼主/PO主"]) {
             BOOL shouldHighlight = settingsCentre.userDefShouldHighlightPO;
             [commandSwitch setOn:shouldHighlight];
         } else if ([command isEqualToString:@"夜间模式"]) {
             [commandSwitch setOn:settingsCentre.nightyMode];
         } else if ([command isEqualToString:@"每月自动清理缓存"]) {
             [commandSwitch setOn:settingsCentre.autoCleanImageCache];
         } else if ([command isEqualToString:@"Monitor Network Performance"]) {
             [commandSwitch setOn:[DartCrowdSourcingConstants isEnabled]];
         }
    } else if (indexPath.section == 1){
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:5];
        commandLabel.textColor = settingsCentre.contentTextColour;
        [commandLabel setText:[regularCommands objectAtIndex:indexPath.row]];
    }
    //cell background colour
    cell.contentView.backgroundColor = settingsCentre.viewBackgroundColour;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){
        NSString *command = [regularCommands objectAtIndex:indexPath.row];
        if ([command isEqualToString:@"图片缓存"]){
            //图片缓存
            [self performSegueWithIdentifier:@"go_image_manager_view_controller_segue" sender:self];
        } else if ([command isEqualToString:@"清除ID信息"]){
            //清除ID信息
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清除ID信息" message:@"确定要清除所有ID信息？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
            [alertView show];
        } else if ([command isEqualToString:@"收藏"]){
            //收藏
            [self performSegueWithIdentifier:@"go_favourite_manager_view_controller_segue" sender:self];
        }
        else if ([command isEqualToString:@"意见反馈"]) {
            if ([czzAppDelegate sharedAppDelegate].homeViewController) {
                UIViewController *feedbackViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedback_view_controller"];
                [[czzAppDelegate sharedAppDelegate].homeViewController pushViewController:feedbackViewController :YES];
//                [self.navigationController pushViewController:feedbackViewController animated:YES];
            }
        }
        else if ([command isEqualToString:@"通知中心"]) {
//            [self performSegueWithIdentifier:@"go_notification_centre_view_controller_segue" sender:self];

            if ([czzAppDelegate sharedAppDelegate].homeViewController) {
                UIViewController *notificationCentreViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"notification_centre_view_controller"];
                [[czzAppDelegate sharedAppDelegate].homeViewController pushViewController:notificationCentreViewController :YES];
            }
        }
        else if ([command isEqualToString:@"清空缓存"]){
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"清空缓存" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"图片缓存", @"帖子缓存", nil];
            [actionSheet showInView:self.view];
        }
    }
}

#pragma mark - prepareCommands for the menu
-(void)prepareCommands{
    [switchCommands addObject:@"显示图片"];
    [switchCommands addObject:@"显示快速滑动按钮"];
    [switchCommands addObject:@"夜间模式"];
    [switchCommands addObject:@"图片下载完毕自动打开"];
    [switchCommands addObject:@"开启帖子缓存"];
    [switchCommands addObject:@"每月自动清理缓存"];
    [switchCommands addObject:@"Monitor Network Performance"];
    [regularCommands addObject:@"图片缓存"];
    [regularCommands addObject:@"清空缓存"];
    [regularCommands addObject:@"清除ID信息"];
    [regularCommands addObject:@"通知中心"];
    [regularCommands addObject:@"意见反馈"];

    [regularCommands addObject:[NSString stringWithFormat:@"版本号: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
}

#pragma mark UIAlertView delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex){
        return;
    }
    if ([alertView.title isEqualToString:@"清除ID信息"]){
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:settingsCentre.a_isle_host]];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
        [[czzAppDelegate sharedAppDelegate] showToast:@"ID信息已清除"];
    }
}

#pragma mark - UIActionSheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex){
        return;
    }
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title hasPrefix:@"图片缓存"]){
        [[czzImageCentre sharedInstance] removeFullSizeImages];
        [[czzImageCentre sharedInstance] removeThumbnails];
        [[czzAppDelegate sharedAppDelegate] showToast:@"图片缓存已清空"];
    }
    else if ([title hasPrefix:@"帖子缓存"]){
        [[czzThreadCacheManager sharedInstance] removeAllThreadCache];
        [[czzAppDelegate sharedAppDelegate] showToast:@"帖子缓存已清空"];
    }
}

#pragma mark UISwitch control handler
-(void)switchDidChanged:(id)sender{
    UISwitch *switchControl = (UISwitch*)sender;
    UIView* v = sender;
    while (![v isKindOfClass:[UITableViewCell class]])
        v = v.superview;
    UITableViewCell *parentCell = (UITableViewCell*)v;
    NSIndexPath *switchedIndexPath = [settingsTableView indexPathForCell:parentCell];
    if (switchedIndexPath.section == 0){
        NSString *command = [switchCommands objectAtIndex:switchedIndexPath.row];
        if ([command isEqualToString:@"显示图片"]){
            //下载图片
            settingsCentre.userDefShouldDisplayThumbnail = switchControl.on;
            [[czzAppDelegate sharedAppDelegate] showToast:@"刷新后生效"];
        }
        else if ([command isEqualToString:@"图片下载完毕自动打开"]){
            //自动打开图片
            settingsCentre.userDefShouldAutoOpenImage = switchControl.on;
        } else if ([command isEqualToString:@"开启帖子缓存"]){
            //开启帖子缓存
            settingsCentre.userDefShouldCacheData = switchControl.on;
        } else if ([command isEqualToString:@"高亮楼主/PO主"]) {
            settingsCentre.userDefShouldHighlightPO = switchControl.on;
        } else if ([command isEqualToString:@"显示快速滑动按钮"]) {
            settingsCentre.userDefShouldShowOnScreenCommand = switchControl.on;
            [[czzAppDelegate sharedAppDelegate] showToast:@"重启后生效"];
        } else if ([command isEqualToString:@"夜间模式"]) {
            settingsCentre.nightyMode = !settingsCentre.nightyMode;
            [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"夜间模式：%@，刷新后生效", settingsCentre.nightyMode ? @"On" : @"Off"]];
            [self.settingsTableView reloadData];
        } else if ([command isEqualToString:@"每月自动清理缓存"]) {
            settingsCentre.autoCleanImageCache = !settingsCentre.autoCleanImageCache;
            [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"每月自动清理缓存： %@", settingsCentre.autoCleanImageCache ? @"On" : @"Off"]];
        } else if ([command isEqualToString:@"Monitor Network Performance"]) {
            [DartCrowdSourcingConstants setEnabled:![DartCrowdSourcingConstants isEnabled]];
        }
        [settingsCentre saveSettings];
    }
}
@end
