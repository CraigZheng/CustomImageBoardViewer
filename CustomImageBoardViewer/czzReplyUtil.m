//
//  czzReplyUtil.m
//  CustomImageBoardViewer
//
//  Created by Craig on 15/01/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzReplyUtil.h"

#import "czzThread.h"
#import "czzPostViewController.h"
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"


@implementation czzReplyUtil

+ (void)postToForum:(czzForum *)forum {
    if (forum){
        czzPostViewController *newPostViewController = [czzPostViewController new];
        newPostViewController.forum = forum;
        newPostViewController.postMode = postViewControllerModeNew;
        [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:newPostViewController] animated:YES completion:nil];
    } else {
        [[AppDelegate window] makeToast:@"未选定一个版块" duration:1.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}

+ (void)replyToThread:(czzThread *)thread inParentThread:(czzThread *)parentThread{
    czzPostViewController *postViewController = [czzPostViewController new];
    postViewController.parentThread = parentThread;
    postViewController.replyToThread = thread;
    postViewController.postMode = postViewControllerModeReply;
    [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:postViewController] animated:YES completion:nil];
}

+ (void)replyMainThread:(czzThread *)thread {
    czzPostViewController *postViewController = [czzPostViewController new];
    postViewController.parentThread = thread;
    postViewController.postMode = postViewControllerModeReply;
    [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:postViewController] animated:YES completion:nil];
}

+ (void)reportThread:(czzThread *)selectedThread inParentThread:(czzThread *)parentThread {
    czzPostViewController *newPostViewController = [czzPostViewController new];
    newPostViewController.postMode = postViewControllerModeReport;
    [[czzNavigationManager sharedManager].delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:newPostViewController] animated:YES completion:nil];
    NSString *reportString = [[settingCentre report_post_placeholder] stringByReplacingOccurrencesOfString:kParentID withString:[NSString stringWithFormat:@"%ld", (long)parentThread.ID]];
    reportString = [reportString stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long)selectedThread.ID]];
    newPostViewController.prefilledString = reportString;
    newPostViewController.title = [NSString stringWithFormat:@"举报:%ld", (long)parentThread.ID];
    //construct a blacklist that to be submitted to my server and pass it to new post view controller
    czzBlacklistEntity *blacklistEntity = [czzBlacklistEntity new];
    blacklistEntity.threadID = selectedThread.ID;
    newPostViewController.blacklistEntity = blacklistEntity;
}

@end
