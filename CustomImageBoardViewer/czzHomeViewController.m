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
#import "czzJSONProcessor.h"
#import "SMXMLDocument.h"
#import "Toast/Toast+UIView.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "czzThreadCacheManager.h"
#import "czzPostViewController.h"
#import "czzBlacklist.h"
#import "czzMoreInfoViewController.h"
#import "czzAppDelegate.h"
#import "czzOnScreenCommandViewController.h"
#import "czzSettingsCentre.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzTextViewHeightCalculator.h"
#import "czzImageViewerUtil.h"
#import "czzNavigationController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "UIBarButtonItem+Badge.h"

#import <CoreText/CoreText.h>

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****"

@interface czzHomeViewController() <czzXMLDownloaderDelegate, /*czzXMLProcessorDelegate,*/ czzJSONProcessorDelegate, UIAlertViewDelegate, czzMenuEnabledTableViewCellProtocol>
@property czzXMLDownloader *xmlDownloader;
@property NSInteger currentPage;
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSInteger pageNumber;
@property NSIndexPath *selectedIndex;
@property czzThread *selectedThread;
@property czzThreadViewController *threadViewController;
@property NSMutableDictionary *downloadedImages;
@property UIViewController *leftController;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForRowsForHorizontalMode;
@property czzOnScreenCommandViewController *onScreenCommandViewController;
@property BOOL shouldDisplayQuickScrollCommand;
@property NSString *thumbnailFolder;
@property czzSettingsCentre *settingsCentre;
@property BOOL shouldHideImageForThisForum;
@property BOOL viewControllerNotInTransition;
@property czzImageViewerUtil *imageViewerUtil;
@property UIRefreshControl* refreshControl;
@property UIBarButtonItem *numberBarButton;
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
@synthesize heightsForRowsForHorizontalMode;
@synthesize onScreenCommandViewController;
@synthesize threadViewController;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize settingsCentre;
@synthesize shouldHideImageForThisForum;
@synthesize viewControllerNotInTransition;
@synthesize imageViewerUtil;
@synthesize menuBarButton;
@synthesize infoBarButton;
@synthesize onScreenImageManagerViewContainer;
@synthesize numberBarButton;
@synthesize forumListButton;
@synthesize refreshControl;
@synthesize settingsBarButton;

static NSString *threadViewBigImageCellIdentifier = @"thread_big_image_cell_identifier";
static NSString *threadViewCellIdentifier = @"thread_cell_identifier";

- (void)viewDidLoad
{
    [super viewDidLoad];
    //right bar button items
    infoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(moreInfoAction)];
    self.navigationItem.rightBarButtonItems = @[menuBarButton, infoBarButton];

    imageViewerUtil = [czzImageViewerUtil new];
    [czzAppDelegate sharedAppDelegate].homeViewController = self; //retain a reference to app delegate, so when entering background, the delegate can inform this controller for further actions
    settingsCentre = [czzSettingsCentre sharedInstance];

    //the target URL string
    baseURLString = settingsCentre.thread_list_host;
    pageNumber = 1; //default page number
    downloadedImages = [NSMutableDictionary new];
    heightsForRows = [NSMutableArray new];
    heightsForRowsForHorizontalMode = [NSMutableArray new];
    //thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    
    //register xib
    [threadTableView registerNib:[UINib nibWithNibName:@"czzThreadViewTableViewCell" bundle:nil] forCellReuseIdentifier:threadViewCellIdentifier];
    [threadTableView registerNib:[UINib nibWithNibName:@"czzThreadViewBigImageTableViewCell" bundle:nil] forCellReuseIdentifier:threadViewBigImageCellIdentifier];
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
                                             selector:@selector(openPickedThread:)
                                                 name:@"ShouldOpenThreadInThreadViewController"
                                               object:nil];
    
    //register a refresh control
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [threadTableView addSubview: refreshControl];
    
    //onscreen command
    onScreenCommandViewController = [[UIStoryboard storyboardWithName:@"OnScreenCommand" bundle:nil] instantiateInitialViewController];
//    onScreenCommandViewController.parentViewController = self;
    [self addChildViewController:onScreenCommandViewController];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [onScreenCommandViewController show];
    
    viewControllerNotInTransition = YES;
    shouldDisplayQuickScrollCommand = settingsCentre.userDefShouldShowOnScreenCommand;
    
    NSTimeInterval delayTime = 4.0;
#ifdef DEBUG
    delayTime = 9999;
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self.forumName.length <= 0) {
            if ([czzAppDelegate sharedAppDelegate].forums.count > 0)
            {
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"用户没有选择板块，随机选择……"];
                @try {
                    int randomIndex = rand() % [czzAppDelegate sharedAppDelegate].forums.count;
                    [self setForumName:[[[czzAppDelegate sharedAppDelegate].forums objectAtIndex:randomIndex] name]];
                    [self refreshThread:self];
                    [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
                }
                @catch (NSException *exception) {
                    
                }
            }
        }
    });
    //check if should show a badget on settings button
    if (!settingsBarButton.customView) {
        UIButton *customImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [customImageButton addTarget:self action:@selector(openSettingsPanel) forControlEvents:UIControlEventTouchUpInside];
        [customImageButton setImage:[[UIImage imageNamed:@"settings.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        settingsBarButton.customView = customImageButton;
    }
    if ([(czzNavigationController*)self.navigationController notificationBannerViewController].needsToBePresented) {
        settingsBarButton.badgeValue = @"1";
    } else {
        settingsBarButton.badgeValue = nil;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    viewControllerNotInTransition = NO;

    [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.viewDeckController.rightController = nil;
    self.viewDeckController.leftController = leftController;
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;

    //on screen image manager view
    czzOnScreenImageManagerViewController *onScreenImgMrg = [(czzNavigationController*)self.navigationController onScreenImageManagerView];
    CGRect frame = onScreenImgMrg.view.frame;
    frame.size = onScreenImageManagerViewContainer.frame.size;
    onScreenImgMrg.view.frame = frame;
    [self addChildViewController:onScreenImgMrg];
    [onScreenImageManagerViewContainer addSubview:onScreenImgMrg.view];

    //change background colour for night mode
    if (settingsCentre.nightyMode)
    {
        if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
            self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];
        } else {
            self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
        }
    } else {
        if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
            self.navigationController.navigationBar.barTintColor = nil;
        } else {
            self.navigationController.navigationBar.tintColor = nil;
        }
    }
    self.view.backgroundColor = settingsCentre.viewBackgroundColour;
}

- (IBAction)sideButtonAction:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

- (IBAction)moreAction:(id)sender {
    [self.navigationController setToolbarHidden:!self.navigationController.toolbarHidden animated:YES];
    return;
}

- (IBAction)postAction:(id)sender {
    [self newPost];
}

- (IBAction)jumpAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"跳页" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (IBAction)searchAction:(id)sender {
    [self performSegueWithIdentifier:@"go_search_view_segue" sender:self];
}

- (IBAction)bookmarkAction:(id)sender {
    [self performSegueWithIdentifier:@"go_favourite_manager_view_controller_segue" sender:self];
}

- (IBAction)settingsAction:(id)sender {
    [self openSettingsPanel];
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"确定"]){
        NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
        if (newPageNumber > 0){
            pageNumber = newPageNumber;
            //clear threads and ready to accept new threads
            [threads removeAllObjects];
            [threadTableView reloadData];
            [heightsForRows removeAllObjects];
            [heightsForRowsForHorizontalMode removeAllObjects];
            [refreshControl beginRefreshing];
            [self loadMoreThread:self.pageNumber];
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)self.pageNumber]];
        } else {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"页码无效..."];
        }
    }
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

#pragma mark - save threads/restore threads, to be used after the app entered or returned from the background
-(void)prepareToEnterBackground {
    if (threads.count > 0) {
        [[czzThreadCacheManager sharedInstance] saveThreadsForHome:threads];
        [[czzThreadCacheManager sharedInstance] saveContentOffSetForHome:threadTableView.contentOffset];
    }
    if (selectedThread) {
        [[czzThreadCacheManager sharedInstance] saveSelectedThreadForHome:selectedThread];
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if (forumName)
        [userDef setObject:forumName forKey:@"forumName"];
    
    //also notify the opened threadview controller
    if (threadViewController) {
        [threadViewController prepareToEnterBackground];
    }
    [userDef synchronize];

}

-(void)restoreFromBackground {
    //if threads count is 0, means this app has just been launched
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if (threads.count == 0) {
        NSArray* cachedThreads = [[czzThreadCacheManager sharedInstance] readThreadsForHome];
        czzThread *cachedSelectedThread = [[czzThreadCacheManager sharedInstance] readSelectedThreadForHome];
        if (cachedThreads.count > 0) {
            [threads addObjectsFromArray:cachedThreads];
            threadTableView.contentOffset = [[czzThreadCacheManager sharedInstance] readContentOffSetForHome];
            [threadTableView reloadData];

            if (cachedSelectedThread) {
                selectedThread = cachedSelectedThread;
                //open selected thread
                if ([[userDef objectForKey:@"ThreadViewControllerActive"] boolValue]) {
                    //push the threadview controller without animation
                    threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_thread_view_controller"];
                    threadViewController.parentThread = selectedThread;
                    [self.navigationController pushViewController:threadViewController animated:NO];
                    [threadViewController restoreFromBackground];
                }
            }
//            pageNumber = threads.count / 20 + 1;
            pageNumber = threads.count / settingsCentre.threads_per_page + 1;
        }
    }
    if ([userDef objectForKey:@"forumName"]) {
        self.forumName = [userDef objectForKey:@"forumName"];
    }
    //delete everything upon restoring is finished
    [userDef removeObjectForKey:@"forumName"];
    [userDef synchronize];
    [[czzThreadCacheManager sharedInstance] removeContentOffSetForHome];
    [[czzThreadCacheManager sharedInstance] removeThreadsForHome];
    [[czzThreadCacheManager sharedInstance] removeSelectedThreadForHome];
}

#pragma mark - more action and commands
-(void)openSettingsPanel{
    UIViewController *settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settings_view_controller"];
    [self.navigationController pushViewController:settingsViewController animated:YES];
    //[self.viewDeckController toggleTopViewAnimated:YES];
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

-(void)moreInfoAction {
    czzMoreInfoViewController *moreInfoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"more_info_view_controller"];
    moreInfoViewController.forumName = self.forumName;
    [self presentViewController:moreInfoViewController animated:YES completion:nil];
}

#pragma mark - UITableView datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (threads.count > 0)
        return threads.count + 1;
    return threads.count;
}

#pragma mark - UITableView delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == threads.count){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (xmlDownloader) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        }
        cell.backgroundColor = [settingsCentre viewBackgroundColour];
        return cell;
    }

    NSString *cell_identifier = [[czzSettingsCentre sharedInstance] userDefShouldUseBigImage] ? threadViewBigImageCellIdentifier : threadViewCellIdentifier;
    czzThread *thread = [threads objectAtIndex:indexPath.row];
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    if (cell){
        cell.delegate = self;
        cell.shouldHighlight = NO;
        cell.shouldAllowClickOnImage = !settingsCentre.userDefShouldUseBigImage;
        cell.parentThread = thread;
        cell.myIndexPath = indexPath;
        cell.myThread = thread;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    @try {
        if (indexPath.row < threads.count) {
            selectedThread = [threads objectAtIndex:selectedIndex.row];
            if (!settingsCentre.shouldAllowOpenBlockedThread) {
                czzBlacklistEntity *blacklistEntity = [[czzBlacklist sharedInstance] blacklistEntityForThreadID:selectedThread.ID];
                if (blacklistEntity){
                    NSLog(@"blacklisted thread");
                    return;
                }
            }
        }
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
    
    NSMutableArray* heightsArray;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        heightsArray = heightsForRowsForHorizontalMode;
    } else {
        heightsArray = heightsForRows;
    }
    CGFloat preferHeight = tableView.rowHeight;
    if (thread){
        //retrive previously saved height
        if (indexPath.row < heightsArray.count) {
            preferHeight = [[heightsArray objectAtIndex:indexPath.row] floatValue];
        } else {
            preferHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:self.view hasImage:thread.thImgSrc.length > 0];
            preferHeight = MAX(tableView.rowHeight, preferHeight);
            [heightsArray addObject:[NSNumber numberWithFloat:preferHeight]];
        }
    }
    return preferHeight;
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
    [heightsForRowsForHorizontalMode removeAllObjects];
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
    NSString *targetURLStringWithPN = [targetURLString stringByAppendingString:[NSString stringWithFormat:@"?page=%ld", (long)pn]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma czzXMLDownloader - thread xml data received
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    [xmlDownloader stop];
    xmlDownloader = nil;
    if (successed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //TODO: provide a way to switch from xml and json format
            czzJSONProcessor *jsonProcessor = [czzJSONProcessor new];
            jsonProcessor.delegate = self;
            [jsonProcessor processThreadListFromData:xmlData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
            [refreshControl endRefreshing];
            [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
            [threadTableView reloadData];
        });
    }
}

#pragma mark - czzXMLProcessorDelegate
-(void)threadListProcessed:(NSArray *)newThreads :(BOOL)success{
    if (success){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (shouldHideImageForThisForum)
            {
                for (czzThread *thread in newThreads) {
                    thread.thImgSrc = nil;
                }
            }
            //process the returned data and pass into the array
            [threads addObjectsFromArray:newThreads];
            //increase the page number if returned data is enough to fill a page
            if (newThreads.count >= 10)
                pageNumber += 1;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [refreshControl endRefreshing];
        [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
        [threadTableView reloadData];
        [self updateNumberButton];
    });
}

-(void)updateNumberButton {
    UIButton *numberButton = [UIButton buttonWithType:UIButtonTypeCustom];
    numberButton.frame = CGRectMake(numberButton.frame.origin.x, numberButton.frame.origin.y, 24, 24);
    numberButton.layer.cornerRadius = 12;
    numberButton.titleLabel.font = [UIFont systemFontOfSize:11];
    numberButton.backgroundColor = [UIColor orangeColor];

    if (!numberBarButton) {
        numberBarButton = [[UIBarButtonItem alloc] initWithCustomView:numberButton];
    } else
        numberBarButton.customView = numberButton;

    [numberButton setTitle:[NSString stringWithFormat:@"%ld", (long) threads.count] forState:UIControlStateNormal];
    if (threads.count <= 0)
        numberButton.hidden = YES;
    else
        numberButton.hidden = NO;
    self.navigationItem.leftBarButtonItems = @[forumListButton, numberBarButton];
}

#pragma Notification handler - forumPicked
-(void)forumPicked:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *forumname = [userInfo objectForKey:@"ForumName"];
    if (forumname){
        self.forumName = forumname;
        //make busy
        [[[czzAppDelegate sharedAppDelegate] window] makeToastActivity];
        [self refreshThread:self];
    }
}

-(void)setForumName:(NSString *)name{
    forumName = name;
    self.title = forumName;
    self.navigationItem.backBarButtonItem.title = self.title;
    //disallow image downloading if specified by remote settings
    shouldHideImageForThisForum = false;
    for (NSString *specifiedForum in settingsCentre.shouldHideImageInForums) {
        if ([specifiedForum isEqualToString:name]) {
            shouldHideImageForThisForum = true;
            break;
        }
    }
    //set the targetURLString with the given forum name
    targetURLString = [baseURLString stringByAppendingString:[self.forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    //access token for the server
    NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
    if (oldToken){
//        targetURLString = [targetURLString stringByAppendingFormat:@"&access_token=%@", oldToken];
    }
}

#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    [self openImageWithPath:imgURL];
}

-(void)imageDownloadedForIndexPath:(NSIndexPath *)index filePath:(NSString *)path isThumbnail:(BOOL)isThumbnail {
    if (isThumbnail)
        [threadTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
    else
        [self openImageWithPath:path];
}

#pragma mark - open images
-(void)openImageWithPath:(NSString*)path{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    if (viewControllerNotInTransition)
        [imageViewerUtil showPhoto:path inViewController:self];
}

#pragma mark - notification handler - favourite thread selected
-(void)openPickedThread:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    if ([userInfo objectForKey:@"PickedThread"]){
        selectedThread = [userInfo objectForKey:@"PickedThread"];
        [self openSelectedThread];
    }
}

-(void)openSelectedThread {
    if (selectedThread) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];
    }
}

#pragma Prepare for segue, here we associate an ID for the incoming thread view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"go_thread_view_segue"]){
        threadViewController = [segue destinationViewController];
        threadViewController.shouldHideImageForThisForum = shouldHideImageForThisForum;
        [threadViewController setParentThread:selectedThread];
    }
}

#pragma sort array - sort the threads so they arrange with ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:YES];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];

    return sortedArray;

}

#pragma mark - rotation events
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    @try {
        NSInteger numberOfVisibleRows = [threadTableView indexPathsForVisibleRows].count / 2;
        if (numberOfVisibleRows > 0) {
            NSIndexPath *currentMiddleIndexPath = [[threadTableView indexPathsForVisibleRows] objectAtIndex:numberOfVisibleRows];
            [threadTableView reloadData];
            [threadTableView scrollToRowAtIndexPath:currentMiddleIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    }
    @catch (NSException *exception) {
    }
}
@end
