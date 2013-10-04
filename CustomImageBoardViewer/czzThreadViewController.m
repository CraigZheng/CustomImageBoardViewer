//
//  czzThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadViewController.h"
#import "czzXMLDownloader.h"
#import "czzThread.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzRightSideViewController.h"

@interface czzThreadViewController ()<czzXMLDownloaderDelegate>
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSMutableSet *originalThreadData;
@property NSMutableArray *threads;
@property czzXMLDownloader *xmlDownloader;
@property NSIndexPath *selectedIndex;
@property czzRightSideViewController *threadMenuViewController;
@property NSInteger pageNumber;
@end

@implementation czzThreadViewController
@synthesize baseURLString;
@synthesize targetURLString;
@synthesize originalThreadData;
@synthesize threads;
@synthesize xmlDownloader;
@synthesize threadTableView;
@synthesize selectedIndex;
@synthesize threadMenuViewController;
@synthesize parentThread;
@synthesize pageNumber;

- (void)viewDidLoad
{
    [super viewDidLoad];
    baseURLString = [NSString stringWithFormat:@"http://h.acfun.tv/api/thread/sub?parentId=%ld", (long)self.parentThread.ID];
    pageNumber = 1;
    originalThreadData = [NSMutableSet new];
    [originalThreadData addObject:parentThread];
    threads = [NSMutableArray new];
    //add the UIRefreshControl to uitableview
    UIRefreshControl *refreCon = [[UIRefreshControl alloc] init];
    [refreCon addTarget:self action:@selector(refreshThread:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreCon;
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"bottom_view_controller"]; //[[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"bottom_view_controller"];
    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.parentThread = parentThread;
    self.viewDeckController.rightController = rightController;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    [self refreshThread:self];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.refreshControl endRefreshing];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] hideToastActivity];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (threads.count > 0)
        return threads.count + 1;
    return threads.count;
}

#pragma UITableView delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == threads.count){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (xmlDownloader) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        } else if (indexPath.row >= parentThread.responseCount + 1){
            cell = [tableView dequeueReusableCellWithIdentifier:@"no_more_cell_identifier"];
        }
        return cell;
    }
    static NSString *CellIdentifier = @"thread_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (cell){
        UILabel *contentLabel = (UILabel*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *posterLabel = (UILabel*)[cell viewWithTag:3];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
        UILabel *imgLabel = (UILabel*)[cell viewWithTag:6];
        UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
        UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];
        
        czzThread *thread = [threads objectAtIndex:indexPath.row];
        [contentLabel setAttributedText:thread.content];
        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        posterLabel.text = [NSString stringWithFormat:@"ID:%@", thread.UID];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"MM-dd, hh:mm"];
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
        //set the title of this thread
        if (indexPath.row == 0)
            self.title = thread.title;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        czzThread *selectedThread = [threads objectAtIndex:indexPath.row];
        if (selectedThread){
            [threadMenuViewController setSelectedThread:selectedThread];
            [self.viewDeckController toggleRightViewAnimated:YES];
        }
    } else {
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
        CGFloat preferHeight = [thread.content.string sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:CGSizeMake(self.view.frame.size.width - 40, MAXFLOAT) lineBreakMode:NSLineBreakByCharWrapping].height + 25;

        return MAX(tableView.rowHeight, preferHeight);
    }
    return tableView.rowHeight;
}

-(void)refreshThread:(id)sender{
    [threads removeAllObjects];
    //reset to default page number
    pageNumber = 1;
    //the first thread in the list
    [threads addObject:parentThread];

    [threadTableView reloadData];
    //stop any possible previous downloader
    if (xmlDownloader)
        [xmlDownloader stop];
    targetURLString = [baseURLString stringByAppendingString:[NSString stringWithFormat:@"&pn=1&count=20&since_id=%ld", (long)parentThread.ID]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLString] delegate:self startNow:YES];
}

-(void)loadMoreThread:(NSInteger)pn{
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"&pn=%ld&count=20&since_id=%ld", (long)pn, (long)parentThread.ID]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    NSMutableArray *newThreas = [NSMutableArray new];
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
                if (thread.ID != 0)
                    [newThreas addObject:thread];
            }
        }
        //if the returned xmlData contains enough threads to fill 1 page, move to next page
        if (newThreas.count >= 20)
            pageNumber ++;
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"无法下载帖子列表，请重试" duration:3.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
    [originalThreadData addObjectsFromArray:newThreas];
    //sort the array
    NSArray *sortedArray = [self sortTheGivenArray:[originalThreadData allObjects]];
    [threads removeAllObjects];
    [threads addObjectsFromArray:sortedArray];
    [threadTableView reloadData];
    [self.refreshControl endRefreshing];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] hideToastActivity];
    //clear out the xml downloader
    [xmlDownloader stop];
    xmlDownloader = nil;
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

#pragma Orientation change
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
}

@end
