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
#import "czzImageCentre.h"
#import "czzImageDownloader.h"
#import "czzAppDelegate.h"
#import "czzRightSideViewController.h"
#import "DACircularProgressView.h"
#import "czzThreadCacheManager.h"
#import "TTTAttributedLabel.h"

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****\n\n"
#define OVERLAY_VIEW 122

@interface czzThreadViewController ()<czzXMLDownloaderDelegate, UIDocumentInteractionControllerDelegate, TTTAttributedLabelDelegate>
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSMutableSet *originalThreadData;
@property NSMutableArray *threads;
@property czzXMLDownloader *xmlDownloader;
@property NSIndexPath *selectedIndex;
@property czzRightSideViewController *threadMenuViewController;
@property NSInteger pageNumber;
@property NSMutableDictionary *downloadedImages;
@property NSMutableSet *currentImageDownloaders;
@property UIDocumentInteractionController *documentInteractionController;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
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
@synthesize downloadedImages;
@synthesize currentImageDownloaders;
@synthesize documentInteractionController;
@synthesize threadsTableViewContentOffSet;

- (void)viewDidLoad
{
    [super viewDidLoad];
    baseURLString = [NSString stringWithFormat:@"http://h.acfun.tv/api/thread/sub?parentId=%ld", (long)self.parentThread.ID];
    pageNumber = 1;
    downloadedImages = [NSMutableDictionary new];
    originalThreadData = [NSMutableSet new];
    [originalThreadData addObject:parentThread];
    threads = [NSMutableArray new];
    currentImageDownloaders = [[czzImageCentre sharedInstance] currentImageDownloaders];
    //add the UIRefreshControl to uitableview
    UIRefreshControl *refreCon = [[UIRefreshControl alloc] init];
    [refreCon addTarget:self action:@selector(refreshThread:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreCon;
    //register for nsnotification centre for image downloaded notification and download progress update notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ThumbnailDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaderUpdated:) name:@"ImageDownloaderProgressUpdated" object:nil];
    self.viewDeckController.rightSize = self.view.frame.size.width/4;

    //try to retrive cached thread from storage
    NSMutableSet *cachedThreads = [[czzThreadCacheManager sharedInstance] readThreads:parentThread];
    if (cachedThreads){
        originalThreadData = cachedThreads;
        //refresh the parent thread
        [originalThreadData removeObject:parentThread];
        [originalThreadData addObject:parentThread];
    }
    [self loadMoreThread:pageNumber];
    [self convertThreadSetToThreadArray];
    //end to retriving cached thread from storage

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"right_menu_view_controller"];    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.parentThread = parentThread;
    threadMenuViewController.selectedThread = parentThread;
    self.viewDeckController.rightController = rightController;
    //disable left controller
    self.viewDeckController.leftController = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (threads.count > 0)
        [threadTableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //stop any downloading xml
    if (xmlDownloader){
        [xmlDownloader stop];
        xmlDownloader = nil;
    }
    //save threads to storage
    [[czzThreadCacheManager sharedInstance] saveThreads:[self sortTheGivenArray:originalThreadData.allObjects]];
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

#pragma mark UITableView delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *CellIdentifier = @"thread_cell_identifier";
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
    czzThread *thread = [threads objectAtIndex:indexPath.row];
    //if image is present
    if (thread.thImgSrc.length != 0){
        CellIdentifier = @"image_thread_cell_identifier";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (cell){
        TTTAttributedLabel *contentLabel = (TTTAttributedLabel*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *posterLabel = (UILabel*)[cell viewWithTag:3];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
        UILabel *imgLabel = (UILabel*)[cell viewWithTag:6];
        UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
        UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];
        UIImageView *previewImageView = (UIImageView*)[cell viewWithTag:9];
        previewImageView.hidden = YES;
        DACircularProgressView *circularProgressView = (DACircularProgressView*)[cell viewWithTag:10];
        circularProgressView.hidden = YES;
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
        //if harmful flag is set, display warning header of harmful thread
        NSMutableAttributedString *contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:thread.content];
        if (thread.harmful){
            NSDictionary *warningStringAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[UIColor redColor]] forKeys:[NSArray arrayWithObject:NSForegroundColorAttributeName]];
            NSAttributedString *warningAttString = [[NSAttributedString alloc] initWithString:WARNINGHEADER attributes:warningStringAttributes];
            
            //add the warning header to the front of content attributed string
            contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:warningAttString];
            [contentAttrString insertAttributedString:thread.content atIndex:warningAttString.length];
        }
        //content label
        contentLabel.delegate = self;
        contentLabel.preferredMaxLayoutWidth = contentLabel.bounds.size.width;
        NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
        //line spacing for iOS 6 devices for compatibility
        paraStyle.lineSpacing = 1.0f;
        /*
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] < 7.0){
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                paraStyle.lineSpacing = 2.0f;
            else
                paraStyle.lineSpacing = 3.0f;
        } else {
            paraStyle.lineSpacing = 2.0f;
        }
         */
        [contentAttrString addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, contentAttrString.length)];
        
        @try {
            [contentLabel setText:contentAttrString.string afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                mutableAttributedString = contentAttrString;
                return mutableAttributedString;
            }];
        }
        @catch (NSException *exception) {
            [contentLabel setText:contentAttrString.string];
        }
        [contentLabel setDataDetectorTypes:NSTextCheckingTypeLink];
        //CLICKABLE CONTENT
        for (NSNumber *replyTo in thread.replyToList) {
            NSInteger rep = [replyTo integerValue];
            NSRange range = [contentLabel.text rangeOfString:[NSString stringWithFormat:@"%ld", (long)rep]];
            @try {
                [contentLabel addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"GOTO://%ld", (long)rep]] withRange:range];

            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }
        }
        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        //set the color to avoid compatible issues in iOS6
        NSMutableAttributedString *uidAttrString = [[NSMutableAttributedString alloc] initWithString:@"UID:" attributes:[NSDictionary dictionaryWithObject:[UIColor colorWithRed:153.0f/255.0f green:102.0f/255.0f blue:51.0f/255.0f alpha:1.0f] forKey:NSForegroundColorAttributeName]];
        [uidAttrString appendAttributedString:thread.UID];
        //manually set the font size to avoid compatible issues in IOS6
        [uidAttrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10] range:NSMakeRange(0, uidAttrString.length)];
        posterLabel.attributedText = uidAttrString;
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"时间:yyyy MM-dd, HH:mm"];
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
        CGFloat sizeToSubtract = 40; //this is the size of left hand side margin and right hand side margin
        //if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
            //sizeToSubtract = 45;
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
            preferHeight += 80;
        }
        return MAX(tableView.rowHeight, preferHeight);
    }
    return tableView.rowHeight;
}

-(void)refreshThread:(id)sender{
    [originalThreadData removeAllObjects];
    [originalThreadData addObject:parentThread];
    //reset to default page number
    pageNumber = 1;
    [threadTableView reloadData];
    [self loadMoreThread:pageNumber];
}

-(void)loadMoreThread:(NSInteger)pn{
    if (!pn)
        pn = pageNumber;
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"&pn=%ld&count=20&since_id=%ld", (long)pn, (long)parentThread.ID]];
    //access token for the server
    NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
    if (oldToken){
        targetURLStringWithPN = [targetURLStringWithPN stringByAppendingFormat:@"&access_token=%@", oldToken];
    }

    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma mark - UIScrollVIew delegate
/*
 this function would be called everytime user dragged the uitableview to the bottom, call load more threads function here
 */
/*
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    NSArray *visibleRows = [self.tableView visibleCells];
    UITableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *path = [self.tableView indexPathForCell:lastVisibleCell];
    if(path.row == threads.count)
    {
        CGRect lastCellRect = [threadTableView rectForRowAtIndexPath:path];
        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.contentSize.height && !xmlDownloader){
            [self performSelector:@selector(loadMoreThread:) withObject:nil];
            [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}
 */

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


#pragma mark czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    NSMutableArray *newThreas = [NSMutableArray new];
    if (successed){
        NSError *error;
        SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
        if (error){
            [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"服务器回传的资料有误，请重试" duration:2.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
            NSLog(@"%@", error);
        }
        for (SMXMLElement *child in xmlDoc.root.children) {
            if ([child.name isEqualToString:@"model"]){
                //create a thread outta this xml data
                czzThread *thread = [[czzThread alloc] initWithSMXMLElement:child];
                if (thread.ID != 0)
                    [newThreas addObject:thread];
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
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"无法下载帖子列表，请重试" duration:2.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
    [originalThreadData addObjectsFromArray:newThreas];
    [self.refreshControl endRefreshing];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] hideToastActivity];
    //clear out the xml downloader
    [xmlDownloader stop];
    xmlDownloader = nil;
    //convert data in set to data in array
    [self convertThreadSetToThreadArray];
}

//this function would convert the original threads in set to nsarray, which is more suitable to be displayed in a uitableview
-(void)convertThreadSetToThreadArray{
    //sort the array
    NSArray *sortedArray = [self sortTheGivenArray:[originalThreadData allObjects]];
    [threads removeAllObjects];
    [threads addObjectsFromArray:sortedArray];
    [threadTableView reloadData];
    if (threads.count > 0){
        pageNumber = (NSInteger)(threads.count / 20) + 1;
    }
}

#pragma mark notification handler - image downloader
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

#pragma mark notification handler - image downloading progress update
-(void)imageDownloaderUpdated:(NSNotification*)notification{
    czzImageDownloader *imgDownloader = [notification.userInfo objectForKey:@"ImageDownloader"];
    if (imgDownloader){
        NSInteger updateIndex = -1;
        for (czzThread *thread in threads) {
            if ([thread.imgSrc isEqualToString:imgDownloader.imageURLString]){
                updateIndex = [threads indexOfObject:thread];
                break;
            }
        }
        if (updateIndex > -1){
            UITableViewCell *cellToUpdate = [threadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:updateIndex inSection:0]];
            DACircularProgressView *circularProgressView = (DACircularProgressView*)[cellToUpdate viewWithTag:10];
            circularProgressView.trackTintColor = [UIColor lightGrayColor];
            if (circularProgressView){
                if (imgDownloader.progress < 1)
                {
                    circularProgressView.hidden = NO;
                    circularProgressView.progress = imgDownloader.progress;
                } else {
                    circularProgressView.hidden = YES;
                }
                [circularProgressView setNeedsDisplay];
            }
        }
    }
}

#pragma mark sort array based on thread ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
        czzThread *first = (czzThread*)a;
        czzThread *second = (czzThread*)b;
        return first.ID > second.ID;
    }];
    return sortedArray;
}

- (IBAction)moreAction:(id)sender {
    [self.viewDeckController toggleRightViewAnimated:YES];
}

#pragma mark UITapGestureRecognizer method
//when user tapped in the ui image view, start/stop the download or show the downloaded image
- (IBAction)userTapInImage:(id)sender {
    NSLog(@"tap");
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer*)sender;
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self.tableView];
    NSIndexPath *tapIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    czzThread *tappedThread = [threads objectAtIndex:tapIndexPath.row];
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:tappedThread.imgSrc.lastPathComponent.lowercaseString])
        {
            [self showDocumentController:file];
            return;
        }
    }
    //Start or stop the image downloader
    if ([[czzImageCentre sharedInstance] containsImageDownloaderWithURL:tappedThread.imgSrc]){
        [[czzImageCentre sharedInstance] stopAndRemoveImageDownloaderWithURL:tappedThread.imgSrc];
        [[czzAppDelegate sharedAppDelegate] showToast:@"图片下载被终止了"];
    } else {
        [[czzImageCentre sharedInstance] downloadImageWithURL:tappedThread.imgSrc];
        [[czzAppDelegate sharedAppDelegate] showToast:@"正在下载图片"];
    }
}

#pragma mark - TTTAttributedLabel delegate
-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url{
    if ([[url scheme] isEqualToString:@"GOTO"]){
        NSInteger gotoThreadID = [[url host] integerValue];
        for (czzThread *thread in threads) {
            if (thread.ID == gotoThreadID){
                //record the current content offset
                threadsTableViewContentOffSet = threadTableView.contentOffset;
                //scroll to the tapped cell
                [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
                //retrive the tapped tableview cell from the tableview
                UITableViewCell *selectedCell = [threadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0]];
                selectedCell = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:selectedCell]];
                [self highlightTableViewCell:selectedCell];
                return;
            }
        }
        [self.view makeToast:[NSString stringWithFormat:@"找不到帖子ID: %d, 可能不在本帖内", gotoThreadID]];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark - high light
-(void)highlightTableViewCell:(UITableViewCell*)tableviewcell{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.threadTableView.contentSize.height)];
    //disable the scrolling view
    self.threadTableView.scrollEnabled = NO;
    containerView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.7f];
    containerView.userInteractionEnabled = YES;
    containerView.tag = OVERLAY_VIEW;
    UIView *newView = [[UIView alloc] initWithFrame:tableviewcell.frame];
    newView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9f];
    [containerView addSubview:tableviewcell];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    containerView.alpha = 0.0f;
    [self.view addSubview:containerView];
    [UIView animateWithDuration:0.2
                     animations:^{containerView.alpha = 1.0f;}
                     completion:^(BOOL finished){[containerView addGestureRecognizer:tapRecognizer];}];
    
}

-(void)tapOnFloatingView:(UIGestureRecognizer*)gestureRecognizer{
    UIView *containerView = [[[czzAppDelegate sharedAppDelegate] window] viewWithTag:OVERLAY_VIEW];
    [UIView animateWithDuration:0.2 animations:^{
        containerView.alpha = 0.0f;
    } completion:^(BOOL finished){
        [containerView removeFromSuperview];
        //scroll back to the original position
    }];
    [threadTableView setContentOffset:threadsTableViewContentOffSet animated:YES];
    self.threadTableView.scrollEnabled = YES;
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
            /*
            BOOL shouldAutoOpenImage = YES;
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldAutoOpenImage"]){
                shouldAutoOpenImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldAutoOpenImage"];
            }
            if (shouldAutoOpenImage) {
                [documentInteractionController presentPreviewAnimated:YES];
            }
             */
        }
    }
}

#pragma mark - rotation change
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    UIView *containerView = [[[czzAppDelegate sharedAppDelegate] window] viewWithTag:OVERLAY_VIEW];
    //if the container view is not nil
    if (containerView)
        [self performSelector:@selector(tapOnFloatingView:) withObject:nil];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
}
@end
