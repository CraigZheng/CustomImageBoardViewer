//
//  czzBottomViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzRightSideViewController.h"
#import "czzThreadViewController.h"
#import "czzPostViewController.h"
#import "Toast+UIView.h"
#import "czzBlacklistEntity.h"
#import "czzImageCentre.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"


@interface czzRightSideViewController ()<UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate>
@property NSMutableArray *replyCommand;
@property NSMutableArray *shareCommand;
@property NSMutableArray *reportCommand;
@property NSMutableArray *allCommand;
@property NSMutableArray *threadDepandentCommand;
@property NSURLConnection *urlCon;
@property NSMutableSet *favouriteThreads;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzRightSideViewController
@synthesize selectedThread;
@synthesize replyCommand;
@synthesize shareCommand;
@synthesize reportCommand;
@synthesize allCommand;
@synthesize parentThread;
@synthesize commandTableView;
@synthesize threadDepandentCommand;
@synthesize urlCon;
@synthesize favouriteThreads;
@synthesize settingsCentre;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //replyCommand = [NSMutableArray arrayWithObjects:@"回复主串", @"回复选定的帖子", @"加入收藏", nil];
    replyCommand = [NSMutableArray arrayWithObjects:@"回复主串", @"回复选定的帖子", @"加入收藏", @"跳页", nil];
    //shareCommand = [NSMutableArray arrayWithObjects:@"复制内容", @"复制选定帖子的ID", nil];
    shareCommand = [NSMutableArray arrayWithObjects:@"复制帖子地址", nil];
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
    NSString* libraryPath = [czzAppDelegate libraryFolder];
    favouriteThreads = [NSKeyedUnarchiver unarchiveObjectWithFile:[libraryPath stringByAppendingPathComponent:@"favourites.dat"]];
    if (!favouriteThreads){
        favouriteThreads = [NSMutableSet new];
    }
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
    return allCommand.count;
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
        [[UIPasteboard generalPasteboard] setString:selectedThread.content.string];
        [[czzAppDelegate sharedAppDelegate] showToast:@"内容已复制"];
    } else if ([command isEqualToString:@"复制选定帖子的ID"]){
        [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%ld", (long)selectedThread.ID]];
        [[czzAppDelegate sharedAppDelegate] showToast:@"ID已复制"];
    } else if ([command hasPrefix:@"复制图片链接"]){
//        NSString *urlString = [settingsCentre.image_host stringByAppendingPathComponent:[self.selectedThread.imgSrc stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
        NSString *urlString = self.selectedThread.imgSrc;
        [[UIPasteboard generalPasteboard] setString:urlString];
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"图片链接已复制"];
        
    } else if ([command isEqualToString:@"回复主串"]){
        [self replyMainAction];
    } else if ([command isEqualToString:@"回复选定的帖子"]){
        [self replySelectedAction];
    } else if ([command isEqualToString:@"举报"]){
        [self reportAction];
    } else if ([command isEqualToString:@"加入收藏"]){
        [self favouriteAction];
    } else if ([command isEqualToString:@"复制帖子地址"]){
        NSString *address = [NSString stringWithFormat:@"http://h.acfun.tv/t/%ld", (long)self.parentThread.ID];
        [[UIPasteboard generalPasteboard] setString:address];
        [[czzAppDelegate sharedAppDelegate] showToast:@"帖子地址已复制"];
    } else if ([command isEqualToString:@"跳页"]) {
        [self.viewDeckController toggleRightViewAnimated:YES completion:
         ^(IIViewDeckController *controller, BOOL success){
             [[NSNotificationCenter defaultCenter] postNotificationName:@"JumpToPageCommand" object:nil userInfo:nil];
        }];
    }
}

-(void)setSelectedThread:(czzThread *)thd{
    selectedThread = thd;
    [threadDepandentCommand removeAllObjects];
    if (self.selectedThread){
        self.title = [NSString stringWithFormat:@"NO:%ld", (long)self.selectedThread.ID];
        if (selectedThread.imgSrc.length != 0)
        {
            //provide an option to allow users to copy the link address of image URL
            [threadDepandentCommand addObject:@"复制图片链接"];
        }
        [commandTableView reloadData];
    }
}

#pragma mark - favirouteAction
-(void)favouriteAction {
    [favouriteThreads addObject:parentThread];
    NSString* libraryPath = [czzAppDelegate libraryFolder];
    [NSKeyedArchiver archiveRootObject:favouriteThreads toFile:[libraryPath stringByAppendingPathComponent:@"favourites.dat"]];
    [[czzAppDelegate sharedAppDelegate].window makeToast:@"已加入收藏"];
}

#pragma mark - reply actions
-(void)replyMainAction {
    czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
    [postViewController setThread:parentThread];
    postViewController.postMode = REPLY_POST;
    [self presentViewController:postViewController animated:YES completion:^{
        [self.viewDeckController toggleRightViewAnimated:NO];
    }];

}

-(void)replySelectedAction {
    czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
    [postViewController setThread:parentThread];
    [postViewController setReplyTo:selectedThread];
    postViewController.postMode = REPLY_POST;
    [self presentViewController:postViewController animated:YES completion:^{
        [self.viewDeckController toggleRightViewAnimated:NO];
    }];
}


-(void)reportAction {
    czzPostViewController *newPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
    [newPostViewController setForumName:@"值班室"];
    newPostViewController.postMode = REPORT_POST;
    [self presentViewController:newPostViewController animated:YES completion:^{
        [self.viewDeckController toggleRightViewAnimated:YES];
        NSString *reportString = [NSString stringWithFormat:@"http://h.acfun.tv/t/%ld?r=%ld\n理由:", (long)parentThread.ID, (long)selectedThread.ID];
        newPostViewController.postTextView.text = reportString;
        newPostViewController.postNaviBar.topItem.title = [NSString stringWithFormat:@"举报:%ld", (long)selectedThread.ID];
        //construct a blacklist that to be submitted to my server and pass it to new post view controller
        czzBlacklistEntity *blacklistEntity = [czzBlacklistEntity new];
        blacklistEntity.threadID = selectedThread.ID;
        newPostViewController.blacklistEntity = blacklistEntity;
    }];
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
        czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [postViewController setThread:parentThread];
        [postViewController setReplyTo:replyToThread];
        postViewController.postMode = REPLY_POST;
        [self presentViewController:postViewController animated:YES completion:nil];
    }
}
@end
