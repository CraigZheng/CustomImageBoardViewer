//
//  czzSettingsViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzSettingsViewController.h"
#import "Toast+UIView.h"
#import "czzImageCacheManager.h"
#import "czzAppDelegate.h"
#import "czzHomeViewController.h"
#import "czzSettingsCentre.h"
#import "czzCookieManagerViewController.h"
#import "czzNotificationCentreTableViewController.h"
#import "czzHomeViewManager.h"
#import "czzWatchListManager.h"

@interface czzSettingsViewController ()<UIAlertViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *debugBarButton;
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
#ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
#endif
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
    
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
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


-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1)
        return [NSString stringWithFormat:@"版本号: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    return nil;
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

         } else if ([command isEqualToString:@"开启串缓存"]){
             BOOL shouldCache = settingsCentre.userDefShouldCacheData;
             [commandSwitch setOn:shouldCache];
         } else if ([command isEqualToString:@"高亮楼主/PO主"]) {
             BOOL shouldHighlight = settingsCentre.userDefShouldHighlightPO;
             [commandSwitch setOn:shouldHighlight];
         } else if ([command isEqualToString:@"夜间模式"]) {
             [commandSwitch setOn:settingsCentre.userDefNightyMode];
         }
         else if ([command isEqualToString:@"大图模式"]) {
             [commandSwitch setOn:settingsCentre.userDefShouldUseBigImage];
         }
         else if ([command isEqualToString:@"每月自动清理缓存"]) {
             [commandSwitch setOn:settingsCentre.userDefShouldCleanCaches];
         } else if ([command isEqualToString:@"Monitor Performance"]) {
//             [commandSwitch setOn:[DartCrowdSourcingConstants isEnabled]];
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
        if ([command isEqualToString:@"图片管理器"]){
            //图片管理器
            UIViewController *viewController = [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"image_manager_view_controller"];
            [self.navigationController pushViewController:viewController animated:YES];
        } else if ([command isEqualToString:@"清除ID信息"]){
            //清除ID信息
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"清除ID信息" message:@"确定要清除所有ID信息？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
            [alertView show];
        } else if ([command isEqualToString:@"意见反馈"]) {
            UIViewController *feedbackViewController = [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"feedback_view_controller"];
            [self.navigationController pushViewController:feedbackViewController animated:YES];
        }
        else if ([command isEqualToString:@"通知中心"]) {
            czzNotificationCentreTableViewController *notificationCentreViewController = [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
            [self.navigationController pushViewController:notificationCentreViewController animated:YES];
        }
        else if ([command isEqualToString:@"清空缓存"]){
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"清空缓存" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"图片管理器", @"串缓存", nil];
            [actionSheet showInView:self.view];
        } else if ([command isEqualToString:@"强制退出"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"强制退出" message:@"立刻退出软件，下次启动时将会重新开始，而不会回复到自动保存的状态" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alertView show];
        } else if ([command isEqualToString:@"捐款给App的作者"]) {
            [self openDonationLink];
        } else if ([command isEqualToString:@"饼干管理器"]) {
            [self.navigationController pushViewController:[czzCookieManagerViewController new] animated:YES];
        } else if ([command isEqualToString:@"LAUNCH UTILITY"]) {
            UIViewController *utilityViewContorller = [[UIStoryboard storyboardWithName:@"Utility" bundle:nil] instantiateInitialViewController];
            if (utilityViewContorller) {
                AppDelegate.window.rootViewController = utilityViewContorller;
                [AppDelegate.window makeKeyAndVisible];
            } else {
                DDLogDebug(@"Utility view contorller nil, cannot instantiate from Utility storyboard file.");
            }
        } else if ([command isEqualToString:@"WATCHLIST"]) {
            
        }
    }
}

#pragma mark - prepareCommands for the menu
-(void)prepareCommands{
    [switchCommands addObject:@"显示图片"];
    [switchCommands addObject:@"显示快速滑动按钮"];
    [switchCommands addObject:@"夜间模式"];
    [switchCommands addObject:@"大图模式"];
    [switchCommands addObject:@"图片下载完毕自动打开"];
//    [switchCommands addObject:@"开启串缓存"];
    [switchCommands addObject:@"每月自动清理缓存"];
    if (settingsCentre.should_allow_dart)
        [switchCommands addObject:@"Monitor Performance"];
    [regularCommands addObject:@"图片管理器"];
    [regularCommands addObject:@"饼干管理器"];
    [regularCommands addObject:@"清空缓存"];
//    [regularCommands addObject:@"清除ID信息"];
    [regularCommands addObject:@"通知中心"];
#ifdef DEBUG
    [regularCommands addObject:@"DEBUG BUILD"];
    [regularCommands addObject:@"LAUNCH UTILITY"];
    [regularCommands addObject:@"WATCHLIST"];
#endif
    NSURL *donationLinkURL = [NSURL URLWithString:settingsCentre.donationLink];
    if (donationLinkURL && settingsCentre.donationLink.length > 0)
        [regularCommands addObject:@"捐款给App的作者"];
    [regularCommands addObject:@"意见反馈"];
    [regularCommands addObject:@"强制退出"];
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
        [AppDelegate showToast:@"ID信息已清除"];
    }
    else if ([alertView.title isEqualToString:@"强制退出"])
    {
        exit(0);
    }
    else if ([alertView.title hasPrefix:@"切换模式"]) {
        settingsCentre.userDefShouldUseBigImage = !settingsCentre.userDefShouldUseBigImage;
        [[NSFileManager defaultManager] removeItemAtPath:[czzAppDelegate threadCacheFolder] error:nil];
        [AppDelegate checkFolders];
        [AppDelegate showToast:[NSString stringWithFormat:@"大图模式：%@", settingsCentre.userDefShouldUseBigImage ? @"On" : @"Off"]];
        [[czzHomeViewManager sharedManager] refresh];
        [settingsCentre saveSettings];
        [self.settingsTableView reloadData];
    }

}

#pragma mark - UIActionSheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex){
        return;
    }
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title hasPrefix:@"图片管理器"]){
        [[czzImageCacheManager sharedInstance] removeFullSizeImages];
        [[czzImageCacheManager sharedInstance] removeThumbnails];
        [AppDelegate showToast:@"图片管理器已清空"];
    }
    else if ([title hasPrefix:@"串缓存"]){
        [[NSFileManager defaultManager] removeItemAtPath:[czzAppDelegate threadCacheFolder] error:nil];
        [AppDelegate checkFolders];
        [AppDelegate showToast:@"串缓存已清空"];
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
            [AppDelegate showToast:@"更改图片显示设置..."];
        }
        else if ([command isEqualToString:@"图片下载完毕自动打开"]){
            //自动打开图片
            settingsCentre.userDefShouldAutoOpenImage = switchControl.on;
        } else if ([command isEqualToString:@"开启串缓存"]){
            //开启串缓存
            settingsCentre.userDefShouldCacheData = switchControl.on;
        } else if ([command isEqualToString:@"高亮楼主/PO主"]) {
            settingsCentre.userDefShouldHighlightPO = switchControl.on;
        } else if ([command isEqualToString:@"显示快速滑动按钮"]) {
            settingsCentre.userDefShouldShowOnScreenCommand = switchControl.on;
            [AppDelegate showToast:@"重启后生效"];
        } else if ([command isEqualToString:@"夜间模式"]) {
            settingsCentre.userDefNightyMode = !settingsCentre.userDefNightyMode;
            [AppDelegate showToast:[NSString stringWithFormat:@"夜间模式：%@", settingsCentre.userDefNightyMode ? @"On" : @"Off"]];
            [[czzHomeViewManager sharedManager] reloadData];
            [self.settingsTableView reloadData];
        }
        else if ([command isEqualToString:@"大图模式"]) {
            [self toggleBigImageMode];
            [self.settingsTableView reloadData];
        }
        else if ([command isEqualToString:@"每月自动清理缓存"]) {
            settingsCentre.userDefShouldCleanCaches = !settingsCentre.userDefShouldCleanCaches;
            [AppDelegate showToast:[NSString stringWithFormat:@"每月自动清理缓存： %@", settingsCentre.userDefShouldCleanCaches ? @"On" : @"Off"]];
        } else if ([command isEqualToString:@"Monitor Performance"]) {
            [self.settingsTableView reloadData];
        }
        [settingsCentre saveSettings];
        [[czzHomeViewManager sharedManager] reloadData];
    }
}

-(void)toggleBigImageMode {
    settingsCentre.userDefShouldUseBigImage = !settingsCentre.userDefShouldUseBigImage;
    [AppDelegate showToast:[NSString stringWithFormat:@"大图模式：%@", settingsCentre.userDefShouldUseBigImage ? @"On" : @"Off"]];

    [[czzHomeViewManager sharedManager] reloadData];
}

-(void)openDonationLink {
    NSURL *donationLinkURL = [NSURL URLWithString:settingsCentre.donationLink];
    if (donationLinkURL && settingsCentre.donationLink.length > 0) {
        if ([[UIApplication sharedApplication] canOpenURL:donationLinkURL]) {
            [[UIApplication sharedApplication] openURL:donationLinkURL];
        }
    } else {
        [AppDelegate showToast:@"谢谢，现在作者并不需要捐款。。。"];
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"settings_view_controller"];
}

//https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=T4UA7Y3NRP8TA&lc=C2&item_name=CraigZheng&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted
@end
