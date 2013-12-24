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

@interface czzSettingsViewController ()<UIAlertViewDelegate, UIActionSheetDelegate>
@property NSMutableArray *commands;
@property NSMutableArray *regularCommands;
@property NSMutableArray *switchCommands;
@end

@implementation czzSettingsViewController
@synthesize settingsTableView;
@synthesize commands, regularCommands, switchCommands;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    commands = [NSMutableArray new];
    regularCommands = [NSMutableArray new];
    switchCommands = [NSMutableArray new];
    [self prepareCommands];
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
        [commandLabel setText:[switchCommands objectAtIndex:indexPath.row]];
        [commandSwitch addTarget:self action:@selector(switchDidChanged:) forControlEvents:UIControlEventValueChanged];
        //set value for switch
        if (indexPath.row == 0){
            //显示图片
            BOOL shouldLoadImages = YES;
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldDownloadThumbnail"])
                shouldLoadImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldDownloadThumbnail"];
            [commandSwitch setOn:shouldLoadImages];
        }
        /*else if (indexPath.row == 1){
            //自动加载
            BOOL shouldAutoLoadMore = NO;
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldAutoLoadMore"])
                shouldAutoLoadMore = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutoLoadMore"];
            [commandSwitch setOn:shouldAutoLoadMore];
        } 
         */else if (indexPath.row == 1){
            //auto open
            BOOL shouldAutoOpen = YES;
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldAutoOpenImage"])
                shouldAutoOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutoOpenImage"];
            [commandSwitch setOn:shouldAutoOpen];

         } else if (indexPath.row == 2){
             //开启帖子缓存
             BOOL shouldCache = YES;
             if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"])
                 shouldCache = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"];
             [commandSwitch setOn:shouldCache];
         }
    } else if (indexPath.section == 1){
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:5];
        [commandLabel setText:[regularCommands objectAtIndex:indexPath.row]];
    }
    return cell;
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
        } else if ([command isEqualToString:@"清空缓存"]){
            //清空缓存
            //select what to remove
            NSString *removeAllImgs = [NSString stringWithFormat:@"清空图片缓存: %@", [[czzImageCentre sharedInstance] totalSize]];
            NSString *removeAllThreadCache = [NSString stringWithFormat:@"清空帖子缓存: %@", [[czzThreadCacheManager sharedInstance] totalSize]];
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"清空缓存" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:removeAllImgs, removeAllThreadCache, nil];
            [actionSheet showInView:self.view];
        }
    }
}

//pragma prepareCommands for the menu
-(void)prepareCommands{
    [switchCommands addObject:@"显示图片"];
    //[switchCommands addObject:@"下拉自动加载帖子"];
    [switchCommands addObject:@"图片下载完毕自动打开"];
    [switchCommands addObject:@"开启帖子缓存"];
    [regularCommands addObject:@"图片缓存"];
    [regularCommands addObject:@"收藏"];
    [regularCommands addObject:@"清空缓存"];
    [regularCommands addObject:@"清除ID信息"];
}

#pragma mark UIAlertView delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == alertView.cancelButtonIndex){
        return;
    }
    if ([alertView.title isEqualToString:@"清除ID信息"]){
        //remove the keyed object in user defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"access_token"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[czzAppDelegate sharedAppDelegate] showToast:@"ID信息已清除"];
    }
}

#pragma mark - UIActionSheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.cancelButtonIndex){
        return;
    }
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title hasPrefix:@"清空图片缓存"]){
        [[czzImageCentre sharedInstance] removeAllImages];
        [[czzAppDelegate sharedAppDelegate] showToast:@"图片缓存已清空"];
    } else if ([title hasPrefix:@"清空帖子缓存"]){
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
        if (switchedIndexPath.row == 0){
            //下载图片
            [[NSUserDefaults standardUserDefaults] setBool:switchControl.on forKey:@"shouldDownloadThumbnail"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[czzAppDelegate sharedAppDelegate] showToast:@"刷新后生效"];
        }
        /*else if (switchedIndexPath.row == 1){
            //自动加载帖子
            [[NSUserDefaults standardUserDefaults] setBool:switchControl.on forKey:@"shouldAutoLoadMore"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } 
         */
        else if (switchedIndexPath.row == 1){
            //自动打开图片
            [[NSUserDefaults standardUserDefaults] setBool:switchControl.on forKey:@"shouldAutoOpenImage"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else if (switchedIndexPath.row == 2){
            //开启帖子缓存
            [[NSUserDefaults standardUserDefaults] setBool:switchControl.on forKey:@"shouldCache"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
@end
