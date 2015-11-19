//
//  czzBottomViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzRightSideViewController.h"
#import "czzPostViewController.h"
#import "czzFavouriteManager.h"
#import "Toast+UIView.h"
#import "czzBlacklistEntity.h"
#import "czzImageCacheManager.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"


@interface czzRightSideViewController ()<UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate>
@property NSMutableArray *replyCommand;
@property NSMutableArray *shareCommand;
@property NSMutableArray *reportCommand;
@property NSMutableArray *allCommand;
@property NSMutableArray *threadDepandentCommand;
@property NSURLConnection *urlCon;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzRightSideViewController
@synthesize replyCommand;
@synthesize shareCommand;
@synthesize reportCommand;
@synthesize allCommand;
@synthesize commandTableView;
@synthesize threadDepandentCommand;
@synthesize urlCon;
@synthesize settingsCentre;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    replyCommand = [NSMutableArray arrayWithObjects:@"回复主串", @"回复选定的串", @"加入收藏", @"跳页", nil];
    shareCommand = [NSMutableArray arrayWithObjects:@"复制串的地址", nil];
    reportCommand = [NSMutableArray arrayWithObjects:@"举报", nil];
    threadDepandentCommand = [NSMutableArray new];
    allCommand = [NSMutableArray new];
    [allCommand addObject:replyCommand];
    [allCommand addObject:shareCommand];
    [allCommand addObject:threadDepandentCommand];
    [allCommand addObject:reportCommand];
    //settings centre
    settingsCentre = [czzSettingsCentre sharedInstance];
    //favourite threads
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(replyToThread:)
                                                 name:@"ReplyAction"
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.commandTableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

#pragma UITableView datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 0; //this view controller is no longer visible to users
//    return allCommand.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray* command = [allCommand objectAtIndex:section];

    return command.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"";
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = @"command_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        NSArray *commandArray = [allCommand objectAtIndex:indexPath.section];
        NSString *command = [commandArray objectAtIndex:indexPath.row];
        if ([command isEqualToString:@"举报"]){
            cell = [tableView dequeueReusableCellWithIdentifier:@"report_cell_identifier"];
        }
        UILabel *commandLabel = (UILabel*)[cell viewWithTag:1];
        [commandLabel setText:command];
        commandLabel.textColor = settingsCentre.contentTextColour;
    }
    cell.backgroundColor = settingsCentre.viewBackgroundColour;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *commandArray = [allCommand objectAtIndex:indexPath.section];
    NSString *command = [commandArray objectAtIndex:indexPath.row];
    if ([command isEqualToString:@"复制内容"]){
        [[UIPasteboard generalPasteboard] setString:self.selectedThread.content.string];
        [AppDelegate showToast:@"内容已复制"];
    } else if ([command isEqualToString:@"复制选定串的ID"]){
        [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%ld", (long)self.selectedThread.ID]];
        [AppDelegate showToast:@"ID已复制"];
    } else if ([command hasPrefix:@"复制图片链接"]){
//        NSString *urlString = [settingsCentre.image_host stringByAppendingPathComponent:[self.selectedThread.imgSrc stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
        NSString *urlString = self.selectedThread.imgSrc;
        [[UIPasteboard generalPasteboard] setString:urlString];
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"图片链接已复制"];
        
    } else if ([command isEqualToString:@"回复主串"]){
        [self replyMainAction];
    } else if ([command isEqualToString:@"回复选定的串"]){
        [self replySelectedAction];
    } else if ([command isEqualToString:@"举报"]){
        [self reportAction];
    } else if ([command isEqualToString:@"加入收藏"]){
        [self favouriteAction];
    } else if ([command isEqualToString:@"复制串的地址"]){
        NSString *address = [[settingCentre share_post_url] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long) self.selectedThread.parentID]];
        [[UIPasteboard generalPasteboard] setString:address];
        [AppDelegate showToast:@"地址已复制"];
    } else if ([command isEqualToString:@"跳页"]) {
        [self.viewDeckController toggleRightViewAnimated:YES completion:
         ^(IIViewDeckController *controller, BOOL success){
             [[NSNotificationCenter defaultCenter] postNotificationName:@"JumpToPageCommand" object:nil userInfo:nil];
        }];
    }
}

-(void)setSelectedThread:(czzThread *)thd{
    _selectedThread = thd;
    [threadDepandentCommand removeAllObjects];
    if (self.selectedThread){
        self.title = [NSString stringWithFormat:@"NO:%ld", (long)self.selectedThread.ID];
        if (_selectedThread.imgSrc.length != 0)
        {
            //provide an option to allow users to copy the link address of image URL
            [threadDepandentCommand addObject:@"复制图片链接"];
        }
        [commandTableView reloadData];
    }
}

#pragma mark - favirouteAction
-(void)favouriteAction {
//    if (self.parentThread)
//        [favouriteManager addFavourite:self.parentThread];
//    [AppDelegate showToast:@"已加入收藏"];
}

#pragma mark - reply actions
-(void)replyMainAction {
    czzPostViewController *postViewController = [czzPostViewController new];
    postViewController.forum = self.forum;
    postViewController.thread = self.parentThread;
    postViewController.postMode = REPLY_POST;
    [[czzNavigationManager sharedManager].delegate pushViewController:postViewController animated:YES];
}

-(void)replySelectedAction {
    czzPostViewController *postViewController = [czzPostViewController new];
    [postViewController setThread:self.parentThread];
    [postViewController setReplyTo:self.selectedThread];
    postViewController.postMode = REPLY_POST;
    [[czzNavigationManager sharedManager].delegate pushViewController:postViewController animated:YES];
}


-(void)reportAction {
    czzPostViewController *newPostViewController = [czzPostViewController new];
    newPostViewController.postMode = REPORT_POST;
    [[czzNavigationManager sharedManager].delegate pushViewController:newPostViewController animated:YES];
    NSString *reportString = [[settingCentre report_post_placeholder] stringByReplacingOccurrencesOfString:kParentID withString:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
    reportString = [reportString stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long)self.selectedThread.ID]];
    newPostViewController.prefilledString = reportString;
    newPostViewController.title = [NSString stringWithFormat:@"举报:%ld", (long)self.parentThread.ID];
    //construct a blacklist that to be submitted to my server and pass it to new post view controller
    czzBlacklistEntity *blacklistEntity = [czzBlacklistEntity new];
    blacklistEntity.threadID = self.selectedThread.ID;
    newPostViewController.blacklistEntity = blacklistEntity;
}

#pragma UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

#pragma mark - notification handler
//reply to thread notification received
-(void)replyToThread:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    czzThread *replyToThread = [userInfo objectForKey:@"ReplyToThread"];
    if (replyToThread){
        czzPostViewController *postViewController = [czzPostViewController new];
        [postViewController setThread:self.parentThread];
        [postViewController setReplyTo:replyToThread];
        postViewController.postMode = REPLY_POST;
        [[czzNavigationManager sharedManager].delegate pushViewController:postViewController animated:YES];
    }
}

#pragma mark - Getters
- (czzThread *)parentThread {
    return self.threadViewManager.parentThread;
}

- (czzForum *)forum {
    return self.threadViewManager.forum;
}

@end
