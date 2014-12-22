//
//  czzViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzHomeViewController.h"
#import "SMXMLDocument.h"
#import "Toast/Toast+UIView.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
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
#import "czzNotificationCentreTableViewController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "UIBarButtonItem+Badge.h"
#import "GSIndeterminateProgressView.h"
#import "czzThreadList.h"

#import <CoreText/CoreText.h>


@interface czzHomeViewController() <UIAlertViewDelegate, czzMenuEnabledTableViewCellProtocol, czzThreadListProtocol, czzOnScreenImageManagerViewControllerDelegate, UIStateRestoring>
@property NSArray *threads;
@property NSArray *verticalHeights;
@property NSArray *horizontalHeights;
@property NSInteger currentPage;
@property NSIndexPath *selectedIndex;
@property czzThread *selectedThread;
@property czzThreadViewController *threadViewController;
@property UIViewController *leftController;
@property czzOnScreenCommandViewController *onScreenCommandViewController;
@property BOOL shouldDisplayQuickScrollCommand;
@property NSString *thumbnailFolder;
@property czzSettingsCentre *settingsCentre;
@property BOOL shouldHideImageForThisForum;
@property BOOL viewControllerNotInTransition;
@property czzImageViewerUtil *imageViewerUtil;
@property UIRefreshControl* refreshControl;
@property UIBarButtonItem *numberBarButton;
@property GSIndeterminateProgressView *progressView;
@property czzThreadList* threadList;
@end

@implementation czzHomeViewController
@synthesize currentPage;
@synthesize threads;
@synthesize verticalHeights;
@synthesize horizontalHeights;
@synthesize threadTableView;
@synthesize selectedIndex;
@synthesize selectedThread;
@synthesize leftController;
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
@synthesize threadList;
@synthesize settingsBarButton;
@synthesize progressView;

static NSString *threadViewBigImageCellIdentifier = @"thread_big_image_cell_identifier";
static NSString *threadViewCellIdentifier = @"thread_cell_identifier";

- (void)viewDidLoad
{
    [super viewDidLoad];
    //thread list, source of all data
    threadList = [czzThreadList new];
    [threadList restorePreviousState];
    //assign delegate and parentViewController
    threadList.delegate = self;
    threadList.parentViewController = self;

    [self copyDataFromThreadList]; //grab any possible data
    
    //progress bar
    progressView = [(czzNavigationController*) self.navigationController progressView];
    
    //right bar button items
    infoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(moreInfoAction)];
    self.navigationItem.leftBarButtonItems = @[forumListButton, infoBarButton];

    imageViewerUtil = [czzImageViewerUtil new];
    [czzAppDelegate sharedAppDelegate].homeViewController = self; //retain a reference to app delegate, so when entering background, the delegate can inform this controller for further actions
    settingsCentre = [czzSettingsCentre sharedInstance];

    //thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    
    //register xib
    [threadTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:threadViewCellIdentifier];
    [threadTableView registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:threadViewBigImageCellIdentifier];
    //configure the view deck controller with half size and tap to close mode
    self.viewDeckController.leftSize = self.view.frame.size.width/4;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    leftController = [self.storyboard instantiateViewControllerWithIdentifier:@"left_side_view_controller"];

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
    [self addChildViewController:onScreenCommandViewController];
    
    //restore previous session
    [self restorePreviousSession];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [onScreenCommandViewController show];
    
    viewControllerNotInTransition = YES;
    shouldDisplayQuickScrollCommand = settingsCentre.userDefShouldShowOnScreenCommand;
    
    NSTimeInterval delayTime = 5.0;
#ifdef DEBUG
    delayTime = 9999;
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (threadList.forumName.length <= 0) {
            if ([czzAppDelegate sharedAppDelegate].forums.count > 0)
            {
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"用户没有选择板块，随机选择……"];
                @try {
                    int randomIndex = rand() % [czzAppDelegate sharedAppDelegate].forums.count;
                    [threadList setForumName:[[[czzAppDelegate sharedAppDelegate].forums objectAtIndex:randomIndex] name]];
                    [self refreshThread:self];
                }
                @catch (NSException *exception) {
                    
                }
            }
        }
    });
    //check if should show a badget on settings button
    UIButton *settingsGearImageButton;
    if (!settingsBarButton.customView) {
        settingsGearImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [settingsGearImageButton setImage:[[UIImage imageNamed:@"settings.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        settingsBarButton.customView = settingsGearImageButton;
    } else {
        settingsGearImageButton = (UIButton*) settingsBarButton.customView;
    }
    if ([[(czzNavigationController*)self.navigationController notificationBannerViewController] shouldShow]) {
        settingsBarButton.badgeValue = @"1";
        [settingsGearImageButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [settingsGearImageButton addTarget:self action:@selector(openNotificationCentre) forControlEvents:UIControlEventTouchUpInside];
    } else {
        settingsBarButton.badgeValue = nil;
        [settingsGearImageButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [settingsGearImageButton addTarget:self action:@selector(openSettingsPanel) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    viewControllerNotInTransition = NO;
    [refreshControl endRefreshing];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.viewDeckController.rightController = nil;
    self.viewDeckController.leftController = leftController;
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;

    //on screen image manager view
    czzOnScreenImageManagerViewController *onScreenImgMrg = [(czzNavigationController*)self.navigationController onScreenImageManagerView];
    onScreenImgMrg.view.frame = onScreenImageManagerViewContainer.bounds;
    onScreenImgMrg.delegate = self;
    [self addChildViewController:onScreenImgMrg];
    [onScreenImageManagerViewContainer addSubview:onScreenImgMrg.view];
    
    self.threadTableView.backgroundColor = settingsCentre.viewBackgroundColour;
    threadList.displayedThread = nil;
}

-(void)restorePreviousSession {
    if (threadList.displayedThread)
    {
        DLog(@"%@", NSStringFromSelector(_cmd));
        threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER];
        threadViewController.shouldRestoreContentOffset = YES;
        threadViewController.parentThread = threadList.displayedThread;
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
        [viewControllers addObject:threadViewController];
        [self.navigationController setViewControllers:viewControllers animated:NO];
    }
}

-(void)copyDataFromThreadList {
    //scroll to previous content offset if current off set is empty
    if (CGPointEqualToPoint(threadTableView.contentOffset, CGPointZero))
    {
        [threadTableView setContentOffset:threadList.currentOffSet animated:NO];
    }
    [self setForumName:threadList.forumName];
    threads = [NSArray arrayWithArray:threadList.threads];
    horizontalHeights = [NSArray arrayWithArray:threadList.horizontalHeights];
    verticalHeights = [NSArray arrayWithArray:threadList.verticalHeights];
    [self updateNumberButton];
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
    UITextField *textInputField = [alertView textFieldAtIndex:0];
    if (textInputField)
    {
        textInputField.keyboardType = UIKeyboardTypeNumberPad;
        textInputField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
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

            //clear threads and ready to accept new threads
            [threadList removeAll];
            [threadTableView reloadData];
            [refreshControl beginRefreshing];
            [threadList removeAll];
            [threadList loadMoreThreads:newPageNumber];

            [[[czzAppDelegate sharedAppDelegate] window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)threadList.pageNumber]];
        } else {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"页码无效..."];
        }
    }
}

#pragma mark - scrollToTop and scrollToBottom
-(void)scrollTableViewToTop {
    [self scrollTableViewToTop:YES];
}

-(void)scrollTableViewToTop:(BOOL)animated {
    [threadTableView setContentOffset:CGPointMake(0.0f, -threadTableView.contentInset.top) animated:animated];
}


-(void)scrollTableViewToBottom {
    @try {
        if (threads.count > 1)
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:threads.count inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark - more action and commands
-(void)openSettingsPanel{
    UIViewController *settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"settings_view_controller"];
    [self.navigationController pushViewController:settingsViewController animated:YES];
    //[self.viewDeckController toggleTopViewAnimated:YES];
}

-(void)openNotificationCentre {
    czzNotificationCentreTableViewController *notificationCentreViewController = [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [self.navigationController pushViewController:notificationCentreViewController animated:YES];
}

-(void)newPost{
    if (threadList.forumName.length > 0){
        czzPostViewController *newPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        [newPostViewController setForumName:threadList.forumName];
        newPostViewController.postMode = NEW_POST;
        [self.navigationController presentViewController:newPostViewController animated:YES completion:nil];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"未选定一个版块" duration:1.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}

-(void)moreInfoAction {
    if (threadList.forumName.length) {
        czzMoreInfoViewController *moreInfoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"more_info_view_controller"];
        moreInfoViewController.forumName = threadList.forumName;
        [self presentViewController:moreInfoViewController animated:YES completion:nil];
    }
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
        if (threadList.isDownloading || threadList.isProcessing) {
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
                    DLog(@"blacklisted thread");
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
        [threadList loadMoreThreads];
        [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row >= threads.count)
        return tableView.rowHeight;
    
    NSArray *heightArray = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? verticalHeights : horizontalHeights;
    CGFloat preferHeight = tableView.rowHeight;
    @try {
        preferHeight = [[heightArray objectAtIndex:indexPath.row] floatValue];
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    return preferHeight;
}

#pragma mark - UIScrollVIew delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    threadList.currentOffSet = scrollView.contentOffset;
}

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
        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.frame.size.height && !(threadList.isDownloading || threadList.isProcessing)){
            [threadList loadMoreThreads];
            [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark - czzThreadListProtocol
-(void)threadListDownloaded:(czzThreadList *)threadList wasSuccessful:(BOOL)wasSuccessful {
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (!wasSuccessful && viewControllerNotInTransition) {
        [refreshControl endRefreshing];
        [progressView stopAnimating];
        [progressView showWarning];
    }
}

-(void)threadListBeginDownloading:(czzThreadList *)threadList {
    if (!progressView.isAnimating)
        [progressView startAnimating];
}

-(void)threadListProcessed:(czzThreadList *)list wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    DLog(@"%@", NSStringFromSelector(_cmd));
    [self copyDataFromThreadList];
    [threadTableView reloadData];
    if (list.pageNumber == 1 && allThreads.count > 1) //just refreshed
    {
        [self scrollTableViewToTop:NO];
    }
    
    [refreshControl endRefreshing];
    if (viewControllerNotInTransition)
        [progressView stopAnimating];
}

#pragma mark - self.refreshControl and download controls
-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:nil];
}

//create a new NSURL outta targetURLString, and reload the content threadTableView
-(void)refreshThread:(id)sender{
//    [threadTableView reloadData];
    //reset to default page number
    [threadList refresh];
}

-(void)updateNumberButton {
    UIButton *numberButton = [UIButton buttonWithType:UIButtonTypeCustom];
    numberButton.frame = CGRectMake(numberButton.frame.origin.x, numberButton.frame.origin.y, 24, 24);
    numberButton.layer.cornerRadius = 12;
    numberButton.titleLabel.font = [UIFont systemFontOfSize:11];
    [numberButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    numberButton.backgroundColor = [UIColor whiteColor];

    if (!numberBarButton) {
        numberBarButton = [[UIBarButtonItem alloc] initWithCustomView:numberButton];
    } else
        numberBarButton.customView = numberButton;

    [numberButton setTitle:[NSString stringWithFormat:@"%ld", (long) threads.count] forState:UIControlStateNormal];
    if (threads.count <= 0) {
        numberButton.hidden = YES;
        self.navigationItem.rightBarButtonItems = @[menuBarButton];
    }
    else {
        numberButton.hidden = NO;
        self.navigationItem.rightBarButtonItems = @[menuBarButton, numberBarButton];
    }
}

#pragma Notification handler - forumPicked
-(void)forumPicked:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *forumname = [userInfo objectForKey:@"ForumName"];
    if (forumname){
        [self setForumName:forumname];
        [self refreshThread:self];
        //disallow image downloading if specified by remote settings
        shouldHideImageForThisForum = false;
        for (NSString *specifiedForum in settingsCentre.shouldHideImageInForums) {
            if ([specifiedForum isEqualToString:forumname]) {
                shouldHideImageForThisForum = true;
                break;
            }
        }
    }
}

-(void)setForumName:(NSString *)name{
    threadList.forumName = name;
    self.title = threadList.forumName;
    self.navigationItem.backBarButtonItem.title = self.title;
}

#pragma mark - czzMenuEnableTableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    [self openImageWithPath:imgURL];
}

-(void)imageDownloadedForIndexPath:(NSIndexPath *)index filePath:(NSString *)path isThumbnail:(BOOL)isThumbnail {
    if (isThumbnail) {
        @try {
            [threadTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
    }
}

#pragma mark - czzOnScreenImageManagerViewControllerDelegate
-(void)onScreenImageManagerDownloadFinished:(czzOnScreenImageManagerViewController *)controller imagePath:(NSString *)path wasSuccessful:(BOOL)success {
    if (success) {
        if ([settingCentre userDefShouldAutoOpenImage])
            [self openImageWithPath:path];
    } else
        DLog(@"img download failed");
}

-(void)onScreenImageManagerSelectedImage:(NSString *)path {
    [self openImageWithPath:path];
}

#pragma mark - open images
-(void)openImageWithPath:(NSString*)path{
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (viewControllerNotInTransition) {
        [imageViewerUtil showPhoto:path inViewController:self];
    }

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
        [threadViewController setParentThread:selectedThread];
        threadList.displayedThread = selectedThread;
    }
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

#pragma mark - pause / restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    DLog(@"%@", NSStringFromSelector(_cmd));
}
@end
