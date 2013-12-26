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
#import "czzMoreInfoViewController.h"
#import "czzImageDownloader.h"
#import "czzImageCentre.h"

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****"

@interface czzHomeViewController ()<czzXMLDownloaderDelegate, UIDocumentInteractionControllerDelegate>
@property czzXMLDownloader *xmlDownloader;
@property NSMutableArray *threads;
@property NSInteger currentPage;
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSInteger pageNumber;
@property NSIndexPath *selectedIndex;
@property czzThread *selectedThread;
@property NSString *forumName;
@property NSMutableDictionary *downloadedImages;
@property UIViewController *leftController;
@property UIDocumentInteractionController *documentInteractionController;
@end

@implementation czzHomeViewController
@synthesize xmlDownloader;
@synthesize threads;
@synthesize currentPage;
@synthesize threadTableView;
@synthesize baseURLString;
@synthesize targetURLString;
@synthesize selectedIndex;
@synthesize selectedThread;
@synthesize pageNumber;
@synthesize forumName;
@synthesize downloadedImages;
@synthesize leftController;
@synthesize documentInteractionController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //the target URL string
    baseURLString = @"http://h.acfun.tv/api/thread/root?forumName=";
    pageNumber = 1; //default page number
    downloadedImages = [NSMutableDictionary new];
    //configure the view deck controller with half size and tap to close mode
    self.viewDeckController.leftSize = self.view.frame.size.width/4;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    leftController = [self.storyboard instantiateViewControllerWithIdentifier:@"left_side_view_controller"];
    threads = [NSMutableArray new];
    //register a notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forumPicked:)
                                                 name:@"ForumNamePicked"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(favouriteThreadPicked:)
                                                 name:@"FavouriteThreadPicked"
                                               object:nil];
    //register for nsnotification centre for image downloaded notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageDownloaded:)
                                                 name:@"ThumbnailDownloaded"
                                               object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self
    //                                         selector:@selector(imageDownloaded:)
    //                                             name:@"ImageDownloaded" object:nil];
    //register a refresh control
    UIRefreshControl* refreCon = [[UIRefreshControl alloc] init];
    [refreCon addTarget:self action:@selector(refreshThread:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreCon;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //if this app is run for the first time, show a brief tutorial
     if (![[NSUserDefaults standardUserDefaults] objectForKey:@"firstTimeRunning"]) {
         [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstTimeRunning"];
         [[NSUserDefaults standardUserDefaults] synchronize];
         [self showTutorial];
     }
    self.viewDeckController.leftController = leftController;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
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

-(void)showTutorial{
    [self.viewDeckController toggleTopViewAnimated:YES completion:^(IIViewDeckController *controller, BOOL b){
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"拉下导航栏以查看更多选项"
                                                                                duration:3.0
                                                                                position:@"center"
                                                                                   title:@"新功能"];
    }];
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
    czzThread *thread = [threads objectAtIndex:indexPath.row];
    //if image is present and settins is set to allow images to show
    if (thread.thImgSrc.length != 0){
        cell_identifier = @"image_thread_cell_identifier";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        UILabel *contentLabel = (UILabel*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *responseLabel = (UILabel*)[cell viewWithTag:4];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
        UILabel *imgLabel = (UILabel*)[cell viewWithTag:6];
        UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
        UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];
        UIImageView *previewImageView = (UIImageView*)[cell viewWithTag:9];
        previewImageView.hidden = YES;
        if (thread.thImgSrc != 0){
            previewImageView.hidden = NO;
            [previewImageView setImage:[UIImage imageNamed:@"Icon.png"]];
            NSString* basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            basePath = [basePath stringByAppendingPathComponent:@"Thumbnails"];
            NSString *filePath = [basePath stringByAppendingPathComponent:[thread.thImgSrc.lastPathComponent stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
            UIImage *previewImage =[UIImage imageWithContentsOfFile:filePath];
            if (previewImage){
                [previewImageView setImage:previewImage];
            } else if ([downloadedImages objectForKey:thread.thImgSrc]){
                [previewImageView setImage:[UIImage imageWithContentsOfFile:[downloadedImages objectForKey:thread.thImgSrc]]];
            }
        }

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
        [contentLabel setLineBreakMode:NSLineBreakByCharWrapping];
        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        [responseLabel setText:[NSString stringWithFormat:@"回应:%ld", (long)thread.responseCount]];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"时间:MM-dd, HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:thread.postDateTime];
        if (thread.imgSrc.length == 0)
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
        if (thread.imgSrc.length == 0)
            [imgLabel setHidden:YES];
        else
            [imgLabel setHidden:NO];
        
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    @try {
        selectedThread = [threads objectAtIndex:selectedIndex.row];
    }
    @catch (NSException *exception) {
        
    }
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
        //add the extra height for the harmful header
        if (thread.harmful){
            CGFloat extraHeaderHeight = [WARNINGHEADER sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(self.view.frame.size.width - sizeToSubtract, MAXFLOAT) lineBreakMode:NSLineBreakByCharWrapping].height;
            preferHeight += extraHeaderHeight;
            
        }
        //height for preview image
        if (thread.thImgSrc.length != 0) {
            preferHeight += 60;
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
            [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"服务器回传的资料有误，请重试" duration:3.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
            NSLog(@"%@", error);
        }
        for (SMXMLElement *child in xmlDoc.root.children) {
            if ([child.name isEqualToString:@"model"]){
                //create a thread outta this xml data
                czzThread *thread = [[czzThread alloc] initWithSMXMLElement:child];
                if (thread.ID != 0) {
                    [newThreads addObject:thread];
                }
            }
            if ([child.name isEqualToString:@"access_token"]){
                //if current access_token is nil, or the responding access_token does not match my current access token, save the responding access_token to a file for later use
                NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
                if (!oldToken || ![oldToken isEqualToString:child.value]){
                    [[NSUserDefaults standardUserDefaults] setObject:child.value forKey:@"access_token"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
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

#pragma Notification handler - forumPicked
-(void)forumPicked:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *forumname = [userInfo objectForKey:@"ForumName"];
    if (forumname){
        self.title = forumname;
        self.forumName = forumname;
        //set the targetURLString with the given forum name
        targetURLString = [baseURLString stringByAppendingString:[self.forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        //access token for the server
        NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
        if (oldToken){
            targetURLString = [targetURLString stringByAppendingFormat:@"&access_token=%@", oldToken];
        }

        [self refreshThread:self];
    }
    //load more info into the top view controller by setting the forumName property for viewDeckController.topController
    UINavigationController *topNavigationController = (UINavigationController*)self.viewDeckController.topController;
    //the root view of top view controller should be the czzMoreInforViewController
    czzMoreInfoViewController *moreInfoViewController = (czzMoreInfoViewController*)topNavigationController.viewControllers[0];
    [moreInfoViewController setForumName:forumname];
    //make busy
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToastActivity];
}

#pragma notification handler - image downloaded
-(void)imageDownloaded:(NSNotification*)notification{
    czzImageDownloader *imgDownloader = [notification.userInfo objectForKey:@"ImageDownloader"];
    BOOL success = [[notification.userInfo objectForKey:@"Success"] boolValue];
    if (!success){
        return;
    }
    if (imgDownloader && imgDownloader.isThumbnail){
        @try {
            if ([notification.userInfo objectForKey:@"FilePath"])
                //store the given file save path
                [downloadedImages setObject:[notification.userInfo objectForKey:@"FilePath"] forKey:imgDownloader.imageURLString];
            for (NSIndexPath *displayedIndexPath in [threadTableView indexPathsForVisibleRows]) {
                czzThread *displayedThread = [threads objectAtIndex:displayedIndexPath.row];
                if ([displayedThread.thImgSrc isEqualToString:imgDownloader.imageURLString]){
                    [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:displayedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
    if (imgDownloader && !imgDownloader.isThumbnail){
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldAutoOpenImage"]) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutoOpenImage"])
                [self showDocumentController:[notification.userInfo objectForKey:@"FilePath"]];
        } else
            [self showDocumentController:[notification.userInfo objectForKey:@"FilePath"]];
    }
}

#pragma notification handler - favourite thread selected
-(void)favouriteThreadPicked:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    if ([userInfo objectForKey:@"PickedThread"]){
        selectedThread = [userInfo objectForKey:@"PickedThread"];
        [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];
    }
}

#pragma mark UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

//show documentcontroller
-(void)showDocumentController:(NSString*)path{
    if (path){
        if (self.isViewLoaded && self.view.window) {
            if (documentInteractionController) {
                [documentInteractionController dismissPreviewAnimated:YES];
            }
            documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
            documentInteractionController.delegate = self;
            [documentInteractionController presentPreviewAnimated:YES];

        }
    }
}

#pragma Prepare for segue, here we associate an ID for the incoming thread view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"go_thread_view_segue"]){
        czzThreadViewController *incomingViewcontroller = [segue destinationViewController];
        [incomingViewcontroller setParentThread:selectedThread];
    }
}

#pragma sort array - sort the threads so they arrange with ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
        czzThread *first = (czzThread*)a;
        czzThread *second = (czzThread*)b;
        return first.ID > second.ID;
    }];
    return sortedArray;
}

@end
