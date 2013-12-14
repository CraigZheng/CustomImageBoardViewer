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
#import "czzNewPostViewController.h"
#import "Toast+UIView.h"
#import "czzBlacklistEntity.h"
#import "czzImageCentre.h"
#import "czzAppDelegate.h"

@interface czzRightSideViewController ()<UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, NSURLConnectionDelegate>
@property NSMutableArray *replyCommand;
@property NSMutableArray *shareCommand;
@property NSMutableArray *reportCommand;
@property NSMutableArray *allCommand;
@property NSMutableArray *threadDepandentCommand;
@property UIDocumentInteractionController *documentInteractionController;
@property NSURLConnection *urlCon;
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
@synthesize documentInteractionController;
@synthesize urlCon;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
    replyCommand = [NSMutableArray arrayWithObjects:@"回复主串", @"回复选定的帖子", nil];
    shareCommand = [NSMutableArray arrayWithObjects:@"复制内容", @"复制选定帖子的ID", nil];
    reportCommand = [NSMutableArray arrayWithObjects:@"举报", nil];
    threadDepandentCommand = [NSMutableArray new];
    allCommand = [NSMutableArray new];
    [allCommand addObject:replyCommand];
    [allCommand addObject:shareCommand];
    [allCommand addObject:threadDepandentCommand];
    [allCommand addObject:reportCommand];
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
    }
    return cell;
}

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
        //[self downloadImage:selectedThread.imgScr];
        /*
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:imgURLString]];
        [self.viewDeckController toggleRightViewAnimated:YES];
         */
        NSString *urlString = [@"http://h.acfun.tv" stringByAppendingPathComponent:[self.selectedThread.imgScr stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
        [[UIPasteboard generalPasteboard] setString:urlString];
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"图片链接已复制"];
        
    } else if ([command isEqualToString:@"回复主串"]){
        czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [postViewController setThread:parentThread];
        [self presentViewController:postViewController animated:YES completion:^{
            [self.viewDeckController toggleRightViewAnimated:NO];
        }];
    } else if ([command isEqualToString:@"回复选定的帖子"]){
        czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [postViewController setThread:parentThread];
        [postViewController setReplyTo:selectedThread];
        [self presentViewController:postViewController animated:YES completion:^{
            [self.viewDeckController toggleRightViewAnimated:NO];
        }];
    } else if ([command isEqualToString:@"举报"]){
        czzNewPostViewController *newPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"new_post_view_controller"];
        [newPostViewController setForumName:@"值班室"];
                newPostViewController.delegate = self;
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
}

-(void)setSelectedThread:(czzThread *)thd{
    selectedThread = thd;
    [threadDepandentCommand removeAllObjects];
    if (self.selectedThread){
        self.title = [NSString stringWithFormat:@"NO:%ld", (long)self.selectedThread.ID];
        if (selectedThread.imgScr.length != 0)
        {
            //provide an option to allow users to copy the link address of image URL
            [threadDepandentCommand addObject:@"复制图片链接"];
        }
        [commandTableView reloadData];
    }
}

#pragma UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

#pragma Download the given image and write to file with NSURLConnection
-(void)downloadImage:(NSString*)imgURLString{
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURLString.lastPathComponent.lowercaseString])
        {
            [self showDocumentController:file];
            return;
        }
    }
    [[czzImageCentre sharedInstance] downloadImageWithURL:imgURLString];
    [[czzAppDelegate sharedAppDelegate] showToast:@"正在下载图片"];
    [self.viewDeckController toggleRightViewAnimated:YES];
}

#pragma notification handler
-(void)imageDownloaded:(NSNotification*)notification{
    NSString *filePath = [notification.userInfo objectForKey:@"FilePath"];
    //if I am still visible, I will present this image in a document interaction controller
    if (self.isViewLoaded && self.view.window)
    {
        [self showDocumentController:filePath];
    } else {
        //or else I should tell others that the download is completed
        NSLog(@"download of img completed");
    }
}

//show documentcontroller
-(void)showDocumentController:(NSString*)path{
    if (path){
        if (self.isViewLoaded && self.view.window) {
            documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
            documentInteractionController.delegate = self;
            [documentInteractionController presentPreviewAnimated:YES];
        }
    }
}
@end
