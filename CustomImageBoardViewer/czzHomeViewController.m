//
//  czzViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzHomeViewController.h"
#import "czzXMLDownloader.h"
#import "SMXMLDocument.h"
#import "Toast/Toast+UIView.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "czzNewPostViewController.h"
#import "czzBlacklist.h"

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****"

@interface czzHomeViewController ()<czzXMLDownloaderDelegate>
@property czzXMLDownloader *xmlDownloader;
@property NSMutableArray *threads;
@property NSInteger currentPage;
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSInteger pageNumber;
@property NSIndexPath *selectedIndex;
@property NSString *forumName;
@end

@implementation czzHomeViewController
@synthesize xmlDownloader;
@synthesize threads;
@synthesize currentPage;
@synthesize threadTableView;
@synthesize baseURLString;
@synthesize targetURLString;
@synthesize selectedIndex;
@synthesize pageNumber;
@synthesize forumName;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //the target URL string
    baseURLString = @"http://h.acfun.tv/api/thread/root?forumName=";
    pageNumber = 1; //default page number
    //configure the view deck controller with half size and tap to close mode
    self.viewDeckController.leftSize = self.view.frame.size.width/4;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    //self.viewDeckController.panningMode = IIViewDeckNoPanning;
    threads = [NSMutableArray new];
    //register a notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forumPicked:)
                                                 name:@"ForumNamePicked"
                                               object:nil];
    //register a refresh control
    UIRefreshControl* refreCon = [[UIRefreshControl alloc] init];
    [refreCon addTarget:self action:@selector(refreshThread:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreCon;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.viewDeckController.rightController = nil;
}

- (IBAction)sideButtonAction:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

- (IBAction)newPostAction:(id)sender {
    if (self.forumName.length > 0){
        czzNewPostViewController *newPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"new_post_view_controller"];
        newPostViewController.delegate = self;
        [newPostViewController setForumName:forumName];
        [self.navigationController presentViewController:newPostViewController animated:YES completion:nil];
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"未选定一个版块" duration:3.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}


#pragma UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (threads.count > 0)
        return threads.count + 1;
    return threads.count;
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == threads.count){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (xmlDownloader) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        }
        return cell;
    }
    NSString *cell_identifier = @"thread_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];

    if (cell){
        UILabel *contentLabel = (UILabel*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *posterLabel = (UILabel*)[cell viewWithTag:3];
        UILabel *responseLabel = (UILabel*)[cell viewWithTag:4];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
        UILabel *imgLabel = (UILabel*)[cell viewWithTag:6];
        UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
        UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];
        
        czzThread *thread = [threads objectAtIndex:indexPath.row];
        //if harmful flag of this thread object is set, inform user that this thread might be harmful
        //also hides the preview
        if (thread.harmful)
        {
            NSDictionary *warningStringAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[UIColor redColor]] forKeys:[NSArray arrayWithObject:NSForegroundColorAttributeName]];
            NSAttributedString *warningAttString = [[NSAttributedString alloc] initWithString:WARNINGHEADER attributes:warningStringAttributes];
            [contentLabel setAttributedText:warningAttString];
        } else {
           //not harmful
            [contentLabel setAttributedText:thread.content];
        }
        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        posterLabel.text = [NSString stringWithFormat:@"ID:%@", thread.UID];
        [responseLabel setText:[NSString stringWithFormat:@"回应:%ld", (long)thread.responseCount]];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"时间:MM-dd, HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:thread.postDateTime];
        if (thread.imgScr.length == 0)
            [imgLabel setHidden:YES];
        else
            [imgLabel setHidden:NO];
        if (thread.sage)
            [sageLabel setHidden:NO];
        else
            [sageLabel setHidden:YES];
        if (thread.lock)
            [lockLabel setHidden:NO];
        else
            [lockLabel setHidden:YES];
        if (thread.imgScr.length == 0)
            [imgLabel setHidden:YES];
        else
            [imgLabel setHidden:NO];
        
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count)
        [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];
    else {
        [self loadMoreThread:pageNumber];
        [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= threads.count)
        return tableView.rowHeight;
    czzThread *thread;
    @try {
        thread = [threads objectAtIndex:indexPath.row];
    }
    @catch (NSException *exception) {
    }
    if (thread){
        CGFloat sizeToSubtract = 40; //this is the size of left hand side margin and right hand side margin
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
            sizeToSubtract = 60;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

            if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
                sizeToSubtract *= (768.0 / 320.0);//the difference between the widths of phone and pad
            else
                sizeToSubtract *= (1024.0 / 480.0);//the difference between the widths of phone and pad
        }
        CGFloat preferHeight = [thread.content.string sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(self.view.frame.size.width - sizeToSubtract, MAXFLOAT) lineBreakMode:NSLineBreakByCharWrapping].height + 25;
        //the height for harmful thread - only minimum height is requried
        if (thread.harmful){
            return tableView.rowHeight;
        }
        return MAX(tableView.rowHeight, preferHeight);
    }

    return tableView.rowHeight;

}

//create a new NSURL outta targetURLString, and reload the content threadTableView
-(void)refreshThread:(id)sender{
    [threads removeAllObjects];
    [threadTableView reloadData];
    //reset to default page number
    pageNumber = 1;
    //stop any possible previous downloader
    if (xmlDownloader)
        [xmlDownloader stop];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLString] delegate:self startNow:YES];
}

-(void)loadMoreThread:(NSInteger)pn{
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *targetURLStringWithPN = [targetURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"&pn=%ld", (long)pn]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma czzXMLDownloader - thread xml data received
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    NSMutableArray *newThreads = [NSMutableArray new];
    if (successed){
        NSError *error;
        SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
        if (error){
            NSLog(@"%@", error);
            return;
        }
        for (SMXMLElement *child in xmlDoc.root.children) {
            if ([child.name isEqualToString:@"status"]){
                NSInteger status = [child.value integerValue];
                if (status != 200)
                    return;
            }
            if ([child.name isEqualToString:@"model"]){
                //create a thread outta this xml data
                czzThread *thread = [[czzThread alloc] initWithSMXMLElement:child];
                if (thread.ID != 0) {
                    [newThreads addObject:thread];
                }
            }
        }
        //increase the page number if returned data is enough to fill a page of 20 threads
        if (newThreads.count >= 20)
            pageNumber += 1;
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"无法下载帖子列表，请重试" duration:3.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];

    }
    //process the returned data and pass into the array
    [threads addObjectsFromArray:newThreads];
    [threadTableView reloadData];
    [self.refreshControl endRefreshing];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] hideToastActivity];
    //clear out the xmlDownloader
    [xmlDownloader stop];
    xmlDownloader = nil;
}

#pragma Notification handler
-(void)forumPicked:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *forumname = [userInfo objectForKey:@"ForumName"];
    if (forumname){
        self.title = forumname;
        self.forumName = forumname;
        //set the targetURLString with the given forum name
        targetURLString = [baseURLString stringByAppendingString:[self.forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [self refreshThread:self];
    }
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToastActivity];
}

#pragma Prepare for segue, here we associate an ID for the incoming thread view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"go_thread_view_segue"]){
        czzThreadViewController *incomingViewcontroller = [segue destinationViewController];
        @try {
            czzThread *selectedThread = [threads objectAtIndex:selectedIndex.row];
            [incomingViewcontroller setParentThread:selectedThread];

        }
        @catch (NSException *exception) {
            
        }
    }
}

#pragma sort array
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
        czzThread *first = (czzThread*)a;
        czzThread *second = (czzThread*)b;
        return first.ID > second.ID;
    }];
    return sortedArray;
}

@end
