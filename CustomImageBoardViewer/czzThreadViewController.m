//
//  czzThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadViewController.h"
#import "czzXMLDownloader.h"
//#import "czzXMLProcessor.h"
#import "czzJSONProcessor.h"
#import "czzThread.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzImageCentre.h"
#import "czzImageDownloader.h"
#import "czzImageViewerUtil.h"
#import "czzAppDelegate.h"
#import "czzRightSideViewController.h"
#import "DACircularProgressView.h"
#import "czzThreadCacheManager.h"
#import "czzHomeViewController.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadRefButton.h"
#import "PartialTransparentView.h"
#import "czzOnScreenCommandViewController.h"
#import "czzSearchViewController.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzMiniThreadViewController.h"

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****\n\n"
#define OVERLAY_VIEW 122

@interface czzThreadViewController ()<czzXMLDownloaderDelegate, czzJSONProcessorDelegate, UIAlertViewDelegate, czzMenuEnabledTableViewCellProtocol, czzMiniThreadViewControllerProtocol>
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSMutableArray *threads;
@property czzXMLDownloader *xmlDownloader;
@property NSIndexPath *selectedIndex;
@property czzRightSideViewController *threadMenuViewController;
@property NSInteger pageNumber;
@property NSMutableDictionary *downloadedImages;
@property NSMutableSet *currentImageDownloaders;
@property czzImageViewerUtil *imageViewerUtil;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
@property BOOL shouldHighlight;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForRowsForHorizontal;
@property czzOnScreenCommandViewController *onScreenCommandViewController;
@property CGPoint restoreFromBackgroundOffSet;
@property BOOL shouldDisplayQuickScrollCommand;
@property NSString *thumbnailFolder;
@property NSString *keywordToSearch;
@property czzSettingsCentre *settingsCentre;
@property UIViewController *rightViewController;
@property UIViewController *topViewController;
@property czzMiniThreadViewController *miniThreadView;
@property BOOL viewControllerNotInTransition;
@property UIRefreshControl *refreshControl;
@end

@implementation czzThreadViewController
@synthesize baseURLString;
@synthesize targetURLString;
//@synthesize originalThreadData;
@synthesize threads;
@synthesize xmlDownloader;
@synthesize threadTableView;
@synthesize selectedIndex;
@synthesize threadMenuViewController;
@synthesize parentThread;
@synthesize pageNumber;
@synthesize downloadedImages;
@synthesize currentImageDownloaders;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldHighlight;
@synthesize shouldHighlightSelectedUser;
@synthesize heightsForRows;
@synthesize heightsForRowsForHorizontal;
@synthesize onScreenCommandViewController;
@synthesize restoreFromBackgroundOffSet;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize keywordToSearch;
@synthesize settingsCentre;
@synthesize shouldHideImageForThisForum;
@synthesize rightViewController;
@synthesize topViewController;
@synthesize viewControllerNotInTransition;
@synthesize miniThreadView;
@synthesize imageViewerUtil;
@synthesize refreshControl;

static NSString *threadViewBigImageCellIdentifier = @"thread_big_image_cell_identifier";
static NSString *threadViewCellIdentifier = @"thread_cell_identifier";

- (void)viewDidLoad
{
    [super viewDidLoad];
    //thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    imageViewerUtil = [czzImageViewerUtil new];
    //settings
    settingsCentre = [czzSettingsCentre sharedInstance];
    shouldHighlight = settingsCentre.userDefShouldHighlightPO;
    baseURLString = [settingsCentre.thread_content_host stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
    pageNumber = 1;
    downloadedImages = [NSMutableDictionary new];
    threads = [NSMutableArray new];
    heightsForRows = [NSMutableArray new];
    heightsForRowsForHorizontal = [NSMutableArray new];
    currentImageDownloaders = [[czzImageCentre sharedInstance] currentImageDownloaders];
    //add the UIRefreshControl to uitableview
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [threadTableView addSubview: refreshControl];
    self.viewDeckController.rightSize = self.view.frame.size.width/4;

    //try to retrive cached thread from storage
    NSArray *cachedThreads = [[czzThreadCacheManager sharedInstance] readThreads:parentThread];
    if (cachedThreads){
        [threads addObjectsFromArray:cachedThreads];
    } else {
        [threads addObject:parentThread];
    }
    NSDictionary *cachedHeights = [[czzThreadCacheManager sharedInstance] readHeightsForThread:parentThread];
    if (cachedHeights) {
        [heightsForRows addObjectsFromArray:[cachedHeights objectForKey:@"VerticalHeights"]];
        [heightsForRowsForHorizontal addObjectsFromArray:[cachedHeights objectForKey:@"HorizontalHeights"]];
    }
    pageNumber = (threads.count - 1)/ 20 + 1;
    //end of retriving cached thread from storage
    
    //register xib
    [self.threadTableView registerNib:[UINib nibWithNibName:@"czzThreadViewTableViewCell" bundle:nil] forCellReuseIdentifier:threadViewCellIdentifier];
    [self.threadTableView registerNib:[UINib nibWithNibName:@"czzThreadViewBigImageTableViewCell" bundle:nil] forCellReuseIdentifier:threadViewBigImageCellIdentifier];
    self.title = parentThread.title;
    self.navigationItem.backBarButtonItem.title = self.title;
    
    //set up custom edit menu
    UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:@selector(menuActionReply:)];
    UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(menuActionCopy:)];
    UIMenuItem *openMenuItem = [[UIMenuItem alloc] initWithTitle:@"打开链接" action:@selector(menuActionOpen:)];
    UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"高亮他" action:@selector(menuActionHighlight:)];
    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, searchMenuItem, openMenuItem]];
    [[UIMenuController sharedMenuController] update];
    //show on screen command
    onScreenCommandViewController = [[UIStoryboard storyboardWithName:@"OnScreenCommand" bundle:nil] instantiateInitialViewController];
    [self addChildViewController:onScreenCommandViewController];
    [onScreenCommandViewController hide];
    shouldDisplayQuickScrollCommand = settingsCentre.userDefShouldShowOnScreenCommand;
    
    //if in foreground, load more threads
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
        [self loadMoreThread:pageNumber];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"right_menu_view_controller"];    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.parentThread = parentThread;
    threadMenuViewController.selectedThread = parentThread;
    self.viewDeckController.rightController = rightController;
    //do not allow panning
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
    //disable left controller
    self.viewDeckController.leftController = nil;
    //register for nsnotification centre for image downloaded notification and download progress update notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ThumbnailDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaderUpdated:) name:@"ImageDownloaderProgressUpdated" object:nil];
    //Jump to command observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PromptForJumpToPage) name:@"JumpToPageCommand" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HighlightThreadSelected:) name:@"HighlightAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SearchUser:) name:@"SearchAction" object:nil];

    //indicate thread view controller is currently active
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSNumber numberWithBool:YES] forKey:@"ThreadViewControllerActive"];
    [userDef synchronize];
    //scroll to restore from background content off set
    if (!CGPointEqualToPoint(CGPointZero, restoreFromBackgroundOffSet)) {
        threadTableView.contentOffset = restoreFromBackgroundOffSet;
        restoreFromBackgroundOffSet = CGPointZero;
    }
    //background colour
    self.view.backgroundColor = settingsCentre.viewBackgroundColour;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //disable right view controller
    self.viewDeckController.rightController = nil;
    //hide on screen command
    [onScreenCommandViewController hide];
    //no longer ready for more push animation
    viewControllerNotInTransition = NO;
    
    //stop any downloading xml
    if (xmlDownloader){
        [xmlDownloader stop];
        xmlDownloader = nil;
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSNumber numberWithBool:NO] forKey:@"ThreadViewControllerActive"];
    [userDef synchronize];
    [self saveThreadsToCache];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //ready for push animation
    viewControllerNotInTransition = YES;
    
}

#pragma mark - enter/exiting background
-(void)prepareToEnterBackground {
    if (threads.count > 1)
        [self saveThreadsToCache];
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSNumber numberWithFloat:threadTableView.contentOffset.y] forKey:@"ThreadViewContentOffSetY"];
    [userDef synchronize];
}

-(void)restoreFromBackground {
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if ([userDef objectForKey:@"ThreadViewContentOffSetY"]) {
        CGFloat offSetY = [[userDef objectForKey:@"ThreadViewContentOffSetY"] floatValue];
        restoreFromBackgroundOffSet = CGPointMake(0, offSetY);
    }

    [userDef removeObjectForKey:@"ThreadViewContentOffSetY"];
    [userDef synchronize];
}

-(void)saveThreadsToCache {
    //save threads to storage
    [[czzThreadCacheManager sharedInstance] saveThreads:threads forThread:parentThread];
    [[czzThreadCacheManager sharedInstance] saveVerticalHeights:heightsForRows andHorizontalHeighs:heightsForRowsForHorizontal ForThread:parentThread];
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
    NSString *cell_identifier = [[czzSettingsCentre sharedInstance] userDefShouldUseBigImage] ? threadViewBigImageCellIdentifier : threadViewCellIdentifier;
    if (indexPath.row == threads.count){
        UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (xmlDownloader) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        } else if (parentThread.responseCount > 20 && ((pageNumber - 1) * 20 + threads.count % 20 - 1) < parentThread.responseCount){

            cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"no_more_cell_identifier"];
        }
        cell.backgroundColor = [settingsCentre viewBackgroundColour];
        return cell;
    }
    czzThread *thread = [threads objectAtIndex:indexPath.row];

    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    // Configure the cell...
    if (cell){
        cell.delegate = self;
        cell.shouldHighlightSelectedUser = shouldHighlightSelectedUser;
        cell.parentThread = parentThread;
        cell.myThread = thread;
    }
    return cell;
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        czzThread *selectedThread = [threads objectAtIndex:indexPath.row];
        if (selectedThread){
            [threadMenuViewController setSelectedThread:selectedThread];
        }
    } else {
        [self loadMoreThread:pageNumber];
        [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < threads.count)
        return YES;
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
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
    NSMutableArray *heightArrays;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        heightArrays = heightsForRowsForHorizontal;
    } else {
        heightArrays = heightsForRows;
    }
    
    CGFloat preferHeight = tableView.rowHeight;
    if (thread){
        //retrive previously saved height
        if (indexPath.row < heightArrays.count) {
            preferHeight = [[heightArrays objectAtIndex:indexPath.row] floatValue];
        } else {
            preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:self.view hasImage:thread.thImgSrc.length > 0];
            preferHeight = MAX(tableView.rowHeight, preferHeight);
            [heightArrays addObject:[NSNumber numberWithFloat:preferHeight]];
        }
    }
    return preferHeight;
}

-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:self];
}

#pragma mark - jump to and download controls
-(void)PromptForJumpToPage{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %ld/%ld", (long) pageNumber, (long) ((parentThread.responseCount + 1) / 20 + 1)] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

#pragma mark - scrollToTop and scrollToBottom 
-(void)scrollTableViewToTop {
    [threadTableView setContentOffset:CGPointMake(0.0f, -threadTableView.contentInset.top) animated:YES];
}

-(void)scrollTableViewToBottom {
    @try {
        if (threads.count > 1)
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:threads.count inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark - highlight thread selected
-(void)HighlightThreadSelected:(NSNotification*)notification {
    czzThread *selectedThread = [notification.userInfo objectForKey:@"HighlightThread"];
    if (selectedThread) {
        if ([shouldHighlightSelectedUser isEqual:selectedThread.UID.string]) {
            shouldHighlightSelectedUser = nil;
        }
        else
            shouldHighlightSelectedUser = selectedThread.UID.string;
        [threadTableView reloadData];
    }
}

#pragma mark - search this particula user 
-(void)SearchUser:(NSNotification*)notification {
    czzThread *selectedThread = [notification.userInfo objectForKey:@"SearchUser"];
    if (selectedThread) {
        keywordToSearch = selectedThread.UID.string;
        [self performSegueWithIdentifier:@"go_search_view_segue" sender:self];
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
//            [originalThreadData removeAllObjects];
            [self.threads removeAllObjects];
            [self.threads addObject:parentThread];
            [heightsForRows removeAllObjects];
            [heightsForRowsForHorizontal removeAllObjects];
            [self.threadTableView reloadData];
            [self.refreshControl beginRefreshing];
            [self loadMoreThread:self.pageNumber];
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long) self.pageNumber]];
        } else {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"页码无效..."];
        }
    }
}

-(void)refreshThread:(id)sender{
    [self.threads removeAllObjects];
    [self.threads addObject:parentThread];
    [heightsForRows removeAllObjects];
    [heightsForRowsForHorizontal removeAllObjects];
//    [originalThreadData removeAllObjects];
//    [originalThreadData addObject:parentThread];
    [threadTableView reloadData];
    //reset to default page number
    pageNumber = 1;
    [self loadMoreThread:pageNumber];
}

-(void)loadMoreThread:(NSInteger)pn{
    if (!pn)
        pn = pageNumber;
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"?page=%ld", (long)pn]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}


#pragma mark - czzMiniThreadViewProtocol
-(void)miniThreadViewFinishedLoading:(BOOL)successful {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (!successful)
        [[czzAppDelegate sharedAppDelegate].window makeToast:[NSString stringWithFormat:@"无法下载:%ld", (long)miniThreadView.threadID]];
    if (viewControllerNotInTransition)
        [self presentViewController:miniThreadView animated:YES completion:nil];
}

-(void)miniThreadWantsToOpenThread:(czzThread*)thread {
    [self dismissViewControllerAnimated:YES completion:^{
        [self switchToParentThread:thread];
    }];
}


#pragma mark - UIScrollVIew delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (onScreenCommandViewController && threads.count > 1 && shouldDisplayQuickScrollCommand) {
        [onScreenCommandViewController show];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    NSArray *visibleRows = [threadTableView visibleCells];
    UITableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *path = [threadTableView indexPathForCell:lastVisibleCell];
    if(path.row == threads.count && threads.count > 0)
    {
        CGRect lastCellRect = [threadTableView rectForRowAtIndexPath:path];
        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.frame.size.height && !xmlDownloader){
            if (((pageNumber - 1) * 20 + threads.count % 20 - 1) < parentThread.responseCount) {
                [self performSelector:@selector(loadMoreThread:) withObject:nil];
                [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}


#pragma mark czzXMLDownloader delegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    [xmlDownloader stop];
    xmlDownloader = nil;
    if (successed) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            czzJSONProcessor *jsonProcessor = [czzJSONProcessor new];
            jsonProcessor.delegate = self;
            [jsonProcessor processSubThreadFromData:xmlData];
//            czzXMLProcessor *xmlProcessor = [czzXMLProcessor new];
//            xmlProcessor.delegate = self;
//            [xmlProcessor processSubThreadFromData:xmlData];
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

#pragma mark - czzJSONProcessorDelegate
-(void)subThreadProcessedForThread:(czzThread *)pThread :(NSArray *)newThread :(BOOL)success{
    if (success){
        NSArray *processedNewThread;
        //the newly downloaded thread might contain duplicate threads, therefore must compare the last chunk of current threads with the new threads, to remove any duplication
        if (threads.count > 1) {
            NSInteger lastChunkIndex = threads.count - 20;
            if (lastChunkIndex < 1)
                lastChunkIndex = 1;
            NSInteger lastChunkLength = threads.count - lastChunkIndex;
            NSRange lastChunkRange = NSMakeRange(lastChunkIndex, lastChunkLength);
            NSArray *lastChunkOfThread = [threads subarrayWithRange:lastChunkRange];
            NSMutableSet *oldThreadSet = [NSMutableSet setWithArray:lastChunkOfThread];
            [oldThreadSet addObjectsFromArray:newThread];
            [threads removeObjectsInRange:lastChunkRange];
            processedNewThread = [self sortTheGivenArray:oldThreadSet.allObjects];
        } else {
            processedNewThread = [self sortTheGivenArray:newThread];
        }
        if (shouldHideImageForThisForum) {
            for (czzThread *thread in processedNewThread) {
                thread.thImgSrc = nil;
            }
        }
        [threads addObjectsFromArray:processedNewThread];
        //swap the first object(the parent thread)
        if (pThread)
            parentThread = pThread;
        [threads replaceObjectAtIndex:0 withObject:parentThread];
        //increase page number if enough to fill a page of 20 threads
        if (processedNewThread.count >= 20) {
            pageNumber ++;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [threadTableView reloadData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    });
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
                if (displayedIndexPath.row >= threads.count)
                    break;
                czzThread *displayedThread = [threads objectAtIndex:displayedIndexPath.row];
                if ([displayedThread.thImgSrc.lastPathComponent isEqualToString:imgDownloader.imageURLString.lastPathComponent]){
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
        if (settingsCentre.userDefShouldAutoOpenImage) 
            [self openImageWithPath:[notification.userInfo objectForKey:@"FilePath"]];
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
            circularProgressView.progressTintColor = [UIColor whiteColor];
            circularProgressView.trackTintColor = [UIColor colorWithRed:0. green:0. blue:0. alpha:0.5];
            circularProgressView.thicknessRatio = 0.1;
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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:YES];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    return sortedArray ? sortedArray : [NSArray new];
}

#pragma mark - UI button actions
- (IBAction)moreAction:(id)sender {
    [self.navigationController setToolbarHidden:!self.navigationController.toolbarHidden animated:YES];
}

- (IBAction)replyAction:(id)sender {
    [threadMenuViewController replyMainAction];
}

- (IBAction)starAction:(id)sender {
    [threadMenuViewController favouriteAction];
}

- (IBAction)jumpAction:(id)sender {
    [self PromptForJumpToPage];
}

- (IBAction)reportAction:(id)sender {
    [threadMenuViewController reportAction];
}

- (IBAction)shareAction:(id)sender {
    //create the thread link - hardcode it
    NSString *threadLink = [NSString stringWithFormat:@"http://h.acfun.tv/t/%ld", (long) parentThread.ID];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:threadLink]] applicationActivities:nil];
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)])
        activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - TableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
        {
            [self openImageWithPath:file];
            return;
        }
    }
}

-(void)userTapInQuotedText:(NSString *)text {
    NSInteger refNumber = text.integerValue;
    
    for (czzThread *thread in threads) {
        if (thread.ID == refNumber){
            //record the current content offset
            threadsTableViewContentOffSet = threadTableView.contentOffset;
            //scroll to the tapped cell
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
            //retrive the tapped tableview cell from the tableview
            UITableViewCell *selectedCell = [threadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0]];
            [self highlightTableViewCell:selectedCell];
            return;
        }
    }
    
    //not in this thread
    [[czzAppDelegate sharedAppDelegate].window makeToast:[NSString stringWithFormat:@"需要下载: %@", text]];
    miniThreadView = [[UIStoryboard storyboardWithName:@"MiniThreadView" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    miniThreadView.delegate = self;
    [miniThreadView setThreadID:refNumber];
}

#pragma mark - high light
-(void)highlightTableViewCell:(UITableViewCell*)tableviewcell{
    //disable the scrolling view
    self.threadTableView.scrollEnabled = NO;
    PartialTransparentView *containerView = [[PartialTransparentView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.threadTableView.contentSize.height) backgroundColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.7f] andTransparentRects:[NSArray arrayWithObject:[NSValue valueWithCGRect:tableviewcell.frame]]];
    
    containerView.userInteractionEnabled = YES;
    containerView.tag = OVERLAY_VIEW;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    containerView.alpha = 0.0f;
    [threadTableView addSubview:containerView];
    [UIView animateWithDuration:0.2
                     animations:^{containerView.alpha = 1.0f;}
                     completion:^(BOOL finished){[containerView addGestureRecognizer:tapRecognizer];}];
    
}

-(void)tapOnFloatingView:(UIGestureRecognizer*)gestureRecognizer{
    PartialTransparentView *containerView = (PartialTransparentView*)[threadTableView viewWithTag:OVERLAY_VIEW];
    [UIView animateWithDuration:0.2 animations:^{
        containerView.alpha = 0.0f;
    } completion:^(BOOL finished){
        [containerView removeFromSuperview];
        //scroll back to the original position
    }];
    CGPoint touchPoint = [gestureRecognizer locationInView:threadTableView];
    NSArray *rectArray = containerView.rectsArray;
    BOOL userTouchInView = NO;
    for (NSValue *rect in rectArray) {
        if (CGRectContainsPoint([rect CGRectValue], touchPoint)) {
            userTouchInView = YES;
            break;
        }
    }
    
    if (!userTouchInView)
        [threadTableView setContentOffset:threadsTableViewContentOffSet animated:YES];
    threadTableView.scrollEnabled = YES;
}

//show image
-(void)openImageWithPath:(NSString*)path{
    if (viewControllerNotInTransition)
        [imageViewerUtil showPhoto:path inViewController:self];
}

#pragma mark - prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go_search_view_segue"]) {
        czzSearchViewController *searchViewController = (czzSearchViewController*)segue.destinationViewController;
        if (keywordToSearch.length > 0)
            searchViewController.predefinedSearchKeyword = keywordToSearch;
    }
}

#pragma mark - switch parent thread
-(void)switchToParentThread:(czzThread*)newParentThread {
    if (newParentThread)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.parentThread = newParentThread;
            baseURLString = [[baseURLString stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long) self.parentThread.ID]];
            [self refreshThread:nil];
        });
    }
}

#pragma mark - rotation change
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    UIView *containerView = [[[czzAppDelegate sharedAppDelegate] window] viewWithTag:OVERLAY_VIEW];
    //if the container view is not nil, deselect it
    if (containerView)
        [self performSelector:@selector(tapOnFloatingView:) withObject:nil];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    @try {
        NSInteger numberOfVisibleRows = [threadTableView indexPathsForVisibleRows].count / 2;
        if (numberOfVisibleRows > 1) {
            NSIndexPath *currentMiddleIndexPath = [[threadTableView indexPathsForVisibleRows] objectAtIndex:numberOfVisibleRows];
            [threadTableView reloadData];
            [threadTableView scrollToRowAtIndexPath:currentMiddleIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    }
    @catch (NSException *exception) {
    }
}


@end
