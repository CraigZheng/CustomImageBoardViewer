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

@interface czzRightSideViewController ()<UITableViewDataSource, UITableViewDelegate>
@property NSMutableArray *replyCommand;
@property NSMutableArray *shareCommand;
@property NSMutableArray *allCommand;
@property NSMutableArray *threadDepandentCommand;
@end

@implementation czzRightSideViewController
@synthesize selectedThread;
@synthesize replyCommand;
@synthesize shareCommand;
@synthesize allCommand;
@synthesize parentThread;
@synthesize commandTableView;
@synthesize threadDepandentCommand;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    replyCommand = [NSMutableArray arrayWithObjects:@"回复主串", @"回复选定的帖子", nil];
    shareCommand = [NSMutableArray arrayWithObjects:@"复制内容", @"复制选定帖子的ID", nil];
    threadDepandentCommand = [NSMutableArray new];
    allCommand = [NSMutableArray new];
    [allCommand addObject:replyCommand];
    [allCommand addObject:shareCommand];
    [allCommand addObject:threadDepandentCommand];
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
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"内容已复制"];
    } else if ([command isEqualToString:@"复制选定帖子的ID"]){
        [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%ld", (long)selectedThread.ID]];
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"ID已复制"];
    } else if ([command isEqualToString:@"复制图片链接"]){
        NSString *imgURLString = [NSString stringWithFormat:@"http://h.acfun.tv%@", [selectedThread.imgScr stringByReplacingOccurrencesOfString:@"~" withString:@""]];
        [[UIPasteboard generalPasteboard] setString:imgURLString];
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"图片链接已复制"];
    } else if ([command isEqualToString:@"回复主串"]){
        czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [postViewController setThread:parentThread];
        [self presentViewController:postViewController animated:YES completion:^{
            [self.viewDeckController toggleRightViewAnimated:YES];
        }];
    } else if ([command isEqualToString:@"回复选定的帖子"]){
        czzPostViewController *postViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [postViewController setThread:parentThread];
        [postViewController setReplyTo:selectedThread];
        [self presentViewController:postViewController animated:YES completion:^{
            [self.viewDeckController toggleRightViewAnimated:YES];
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
@end
