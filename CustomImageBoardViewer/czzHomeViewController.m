//
//  czzViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzHomeViewController.h"
#import "czzXMLDownloader.h"
#import "czzXMLProcessor.h"
#import "SMXMLDocument.h"
#import "Toast/Toast+UIView.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "czzPostViewController.h"
#import "czzBlacklist.h"
#import "czzMoreInfoViewController.h"
#import "czzImageDownloader.h"
#import "czzImageCentre.h"
#import "czzAppDelegate.h"
#import <CoreText/CoreText.h>

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****"

@interface czzHomeViewController ()<czzXMLDownloaderDelegate, czzXMLProcessorDelegate, UIDocumentInteractionControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
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
@property NSMutableArray *heightsForRows;
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
@synthesize heightsForRows;
@synthesize documentInteractionController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //the target URL string
    baseURLString = @"http://h.acfun.tv/api/thread/root?forumName=";
    pageNumber = 1; //default page number
    downloadedImages = [NSMutableDictionary new];
    heightsForRows = [NSMutableArray new];
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

    //register a refresh control
    UIRefreshControl* refreCon = [[UIRefreshControl alloc] init];
    [refreCon addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreCon;
    
    //download a message from the server
    czzXMLDownloader *msgDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:[[czzAppDelegate sharedAppDelegate].myhost stringByAppendingPathComponent:@"message.xml"]] delegate:self startNow:YES];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    /*
    //if this app is run for the first time, show a brief tutorial
     if (![[NSUserDefaults standardUserDefaults] objectForKey:@"firstTimeRunning"]) {
         [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstTimeRunning"];
         [[NSUserDefaults standardUserDefaults] synchronize];

         [self showTutorial];
     }
     */
    self.viewDeckController.leftController = leftController;
    //if a forum has not been selected and is not the first time running
    if (!self.forumName && [[NSUserDefaults standardUserDefaults] objectForKey:@"firstTimeRunning"])
        [self.viewDeckController toggleLeftViewAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.viewDeckController.rightController = nil;
}

- (IBAction)sideButtonAction:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

- (IBAction)moreAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"更多功能" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"发表新帖", @"跳页", @"设置", nil];
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"发表新帖"])
        [self newPost];
    else if ([buttonTitle isEqualToString:@"设置"])
        [self openSettingsPanel];
    else if ([buttonTitle isEqualToString:@"跳页"])
    {
        //allows user to jump to a specified page number
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"跳页" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    }
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"确定"]){
        NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
        if (newPageNumber > 0){
            self.pageNumber = newPageNumber;
            //clear threads and ready to accept new threads
            [self.threads removeAllObjects];
            [self.threadTableView reloadData];
            [heightsForRows removeAllObjects];
            [self.refreshControl beginRefreshing];
            [self loadMoreThread:self.pageNumber];
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)self.pageNumber]];
        } else {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"页码无效..."];
        }
    }
}

-(void)openSettingsPanel{
    [self.viewDeckController toggleTopViewAnimated:YES];
}

-(void)newPost{
    if (self.forumName.length > 0){
        czzPostViewController *newPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [newPostViewController setForumName:forumName];
        newPostViewController.postMode = NEW_POST;
        [self.navigationController presentViewController:newPostViewController animated:YES completion:nil];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"未选定一个版块" duration:1.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}

-(void)showTutorial{
    [self.viewDeckController toggleTopViewAnimated:YES completion:^(IIViewDeckController *controller, BOOL b){
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"拉下导航栏以查看更多选项"
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        UITextView *contentTextView = (UITextView*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *responseLabel = (UILabel*)[cell viewWithTag:4];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
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
            if (previewImage && previewImage.size.width > 0 && previewImage.size.height > 0){
                [previewImageView setImage:previewImage];
            } else if ([downloadedImages objectForKey:thread.thImgSrc]){
                [previewImageView setImage:[UIImage imageWithContentsOfFile:[downloadedImages objectForKey:thread.thImgSrc]]];
            }
        }

        //content text view
        //if harmful flag of this thread object is set, inform user that this thread might be harmful
        //also hides the preview
        if (thread.harmful)
        {
            NSDictionary *warningStringAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[UIColor lightGrayColor]] forKeys:[NSArray arrayWithObject:NSForegroundColorAttributeName]];
            NSAttributedString *warningAttString = [[NSAttributedString alloc] initWithString:WARNINGHEADER attributes:warningStringAttributes];
            [contentTextView setAttributedText:warningAttString];
        } else {
           //not harmful
            [contentTextView setAttributedText:thread.content];
        }

        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        [responseLabel setText:[NSString stringWithFormat:@"回应:%ld", (long)thread.responseCount]];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"时间:MM-dd, HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:thread.postDateTime];
        if (thread.sage)
            [sageLabel setHidden:NO];
        else
            [sageLabel setHidden:YES];
        if (thread.lock)
            [lockLabel setHidden:NO];
        else
            [lockLabel setHidden:YES];
        
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
    
    CGFloat preferHeight = tableView.rowHeight;
    if (thread){
        //retrive previously saved height
        if (indexPath.row < heightsForRows.count) {
            preferHeight = [[heightsForRows objectAtIndex:indexPath.row] floatValue];
        } else {
            UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
            newHiddenTextView.hidden = YES;
            [self.view addSubview:newHiddenTextView];
            newHiddenTextView.attributedText = thread.content;
            preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 20;
            [newHiddenTextView removeFromSuperview];
            //height for preview image
            if (thread.thImgSrc.length != 0) {
                preferHeight += 82;
            }
            preferHeight = MAX(tableView.rowHeight, preferHeight);
            [heightsForRows addObject:[NSNumber numberWithFloat:preferHeight]];
        }
    }
    return preferHeight;
    
}

#pragma mark - UIScrollVIew delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    NSArray *visibleRows = [self.tableView visibleCells];
    UITableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *path = [self.tableView indexPathForCell:lastVisibleCell];
    if(path.row == threads.count && threads.count > 0)
    {
        CGRect lastCellRect = [threadTableView rectForRowAtIndexPath:path];
        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.frame.size.height && !xmlDownloader){
            [self performSelector:@selector(loadMoreThread:) withObject:nil];
            [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark - self.refreshControl and download controls
-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:nil];
}

//create a new NSURL outta targetURLString, and reload the content threadTableView
-(void)refreshThread:(id)sender{
    [threads removeAllObjects];
    [heightsForRows removeAllObjects];
    [threadTableView reloadData];
    //reset to default page number
    pageNumber = 1;
    //stop any possible previous downloader
    if (xmlDownloader)
        [xmlDownloader stop];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLString] delegate:self startNow:YES];
}

-(void)loadMoreThread:(NSInteger)pn{
    if (!pn)
        pn = pageNumber;
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *targetURLStringWithPN = [targetURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"&pn=%ld", (long)pn]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma czzXMLDownloader - thread xml data received
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    [xmlDownloader stop];
    xmlDownloader = nil;
    if (successed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            czzXMLProcessor *xmlProcessor = [czzXMLProcessor new];
            xmlProcessor.delegate = self;
            [xmlProcessor processThreadListFromData:xmlData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
            [self.refreshControl endRefreshing];
            [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
            [threadTableView reloadData];
        });
    }
}

#pragma mark - czzXMLProcessorDelegate
-(void)threadListProcessed:(NSArray *)newThreads :(BOOL)success{
    if (success){
        dispatch_async(dispatch_get_main_queue(), ^{
            //process the returned data and pass into the array
            [threads addObjectsFromArray:newThreads];
            //increase the page number if returned data is enough to fill a page of 20 threads
            if (newThreads.count >= 20)
                pageNumber += 1;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
        [threadTableView reloadData];
    });
}

-(void)messageProcessed:(NSString *)title :(NSString *)message :(NSInteger)howLong{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:message duration:howLong position:@"center" title:title];
    });
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
    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
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
                if (displayedIndexPath.row > threads.count)
                    break;
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
        [self.navigationController popToRootViewControllerAnimated:NO];
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
