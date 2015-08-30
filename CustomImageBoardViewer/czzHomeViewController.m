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
#import "czzSettingsCentre.h"
#import "czzImageViewerUtil.h"
#import "czzNavigationController.h"
#import "czzNotificationCentreTableViewController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "UIBarButtonItem+Badge.h"
#import "GSIndeterminateProgressView.h"
#import "czzHomeViewModelManager.h"
#import "czzForumManager.h"
#import "czzHomeViewDelegate.h"
#import "czzThreadViewModelManager.h"

#import "czzHomeTableViewDataSource.h"

#import <CoreText/CoreText.h>


@interface czzHomeViewController() <UIAlertViewDelegate, czzOnScreenImageManagerViewControllerDelegate, UIStateRestoring>
@property UIViewController *leftController;
@property (assign, nonatomic) BOOL shouldDisplayQuickScrollCommand;
@property (strong, nonatomic) NSString *thumbnailFolder;
@property czzSettingsCentre *settingsCentre;
@property (assign, nonatomic) BOOL shouldHideImageForThisForum;
@property (assign, nonatomic) BOOL viewControllerNotInTransition;
@property czzImageViewerUtil *imageViewerUtil;
@property UIRefreshControl* refreshControl;
@property UIBarButtonItem *numberBarButton;
@property GSIndeterminateProgressView *progressView;

@property czzHomeTableViewDataSource *tableViewDataSource;
@property czzHomeViewDelegate *homeViewDelegate;
@end

@implementation czzHomeViewController
@synthesize threadTableView;
@synthesize leftController;
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
@synthesize viewModelManager;
@synthesize settingsBarButton;
@synthesize progressView;

@synthesize tableViewDataSource;
@synthesize homeViewDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //thread list, source of all data
    if (!viewModelManager)
        viewModelManager = [czzHomeViewModelManager sharedManager];

    //assign delegate and parentViewController
    viewModelManager.delegate = self;
    
    //progress bar
    progressView = [(czzNavigationController*) self.navigationController progressView];
    
    //right bar button items
    infoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(moreInfoAction:)];
    self.navigationItem.leftBarButtonItems = @[forumListButton, infoBarButton];

    imageViewerUtil = [czzImageViewerUtil new];
    settingsCentre = settingCentre;

    //thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    
    //assign a custom tableview data source
    threadTableView.dataSource = tableViewDataSource = [czzHomeTableViewDataSource initWithViewModelManager:self.viewModelManager];
    threadTableView.delegate = homeViewDelegate = [czzHomeViewDelegate initWithViewModelManager:self.viewModelManager];
    tableViewDataSource.tableViewDelegate = homeViewDelegate;
    
    // Load data into tableview
    [self updateTableView];
    if (!CGPointEqualToPoint(CGPointZero, self.viewModelManager.currentOffSet)) {
        [self.threadTableView setContentOffset:self.viewModelManager.currentOffSet animated:NO];
    }
    // Set the currentOffSet back to zero
    self.viewModelManager.currentOffSet = CGPointZero;

    //configure the view deck controller with half size and tap to close mode
    self.viewDeckController.leftSize = self.view.frame.size.width/4;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    leftController = [self.storyboard instantiateViewControllerWithIdentifier:@"left_side_view_controller"];

    //register a notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forumPicked:)
                                                 name:kForumPickedNotification
                                               object:nil];
    
    //register a refresh control
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [threadTableView addSubview: refreshControl];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    viewControllerNotInTransition = YES;
    shouldDisplayQuickScrollCommand = settingsCentre.userDefShouldShowOnScreenCommand;
    
    NSTimeInterval delayTime = 8.0;
#ifdef DEBUG
    delayTime = 9999;
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!viewModelManager.forum) {
            if ([czzForumManager sharedManager].forums.count > 0)
            {
                [AppDelegate.window makeToast:@"用户没有选择板块，随机选择……"];
                @try {
                    int randomIndex = rand() % [czzForumManager sharedManager].forums.count;
                    [viewModelManager setForum:[[czzForumManager sharedManager].forums objectAtIndex:randomIndex]];
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
        //create a container view that has an image button as its sub view
        settingsGearImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 37)];
        settingsGearImageButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [settingsGearImageButton setImage:[[UIImage imageNamed:@"settings.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        settingsGearImageButton.tag = 999;
        //add the container view
        settingsBarButton.customView = settingsGearImageButton;
    } else {
        //retrive the gear image button
        settingsGearImageButton = (UIButton*) [settingsBarButton.customView viewWithTag:999];
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
    czzOnScreenImageManagerViewController *onScreenImgMrg = [NavigationManager.delegate onScreenImageManagerView];
    onScreenImgMrg.delegate = homeViewDelegate;
    [self addChildViewController:onScreenImgMrg];
    [onScreenImageManagerViewContainer addSubview:onScreenImgMrg.view];
    
    self.threadTableView.backgroundColor = settingsCentre.viewBackgroundColour;
    
    //if big image mode, perform a reload
    if ([settingCentre userDefShouldUseBigImage])
    {
        [threadTableView reloadData];
    }
}

/*
 This method would update the contents related to the table view
 */
-(void)updateTableView {
    [self setSelectedForum:viewModelManager.forum];
    [self updateNumberButton];
    [threadTableView reloadData];
}

#pragma mark - State perserving
- (NSString*)saveCurrentState {
    self.viewModelManager.currentOffSet = self.threadTableView.contentOffset;
    return [self.viewModelManager saveCurrentState];
}

#pragma mark - ButtonActions
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
            [viewModelManager removeAll];
            [self updateTableView];
            [refreshControl beginRefreshing];
            [viewModelManager loadMoreThreads:newPageNumber];

            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)viewModelManager.pageNumber]];
        } else {
            [[AppDelegate window] makeToast:@"页码无效..."];
        }
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
    if (viewModelManager.forum){
        czzPostViewController *newPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"post_view_controller"];
        newPostViewController.forum = viewModelManager.forum;
        newPostViewController.postMode = NEW_POST;
        [self.navigationController presentViewController:newPostViewController animated:YES completion:nil];
    } else {
        [[AppDelegate window] makeToast:@"未选定一个版块" duration:1.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}

-(IBAction)moreInfoAction:(id)sender {
    if (viewModelManager.forum) {
        czzMoreInfoViewController *moreInfoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"more_info_view_controller"];
        moreInfoViewController.forum = viewModelManager.forum;
        [self presentViewController:moreInfoViewController animated:YES completion:nil];
    }
}

#pragma mark - czzThreadListProtocol
- (void)viewModelManagerWantsToReload:(czzHomeViewModelManager *)manager {
    if (manager.threads.count) {
        [self.threadTableView reloadData];
    }
}

-(void)viewModelManager:(czzHomeViewModelManager *)threadList downloadSuccessful:(BOOL)wasSuccessful {
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (!wasSuccessful && viewControllerNotInTransition) {
        [refreshControl endRefreshing];
        [progressView stopAnimating];
        [progressView showWarning];
    }
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
}

-(void)viewModelManagerBeginDownloading:(czzHomeViewModelManager *)threadList {
    if (!progressView.isAnimating)
        [progressView startAnimating];
    
}

-(void)viewModelManager:(czzHomeViewModelManager *)list processedThreadData:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    DLog(@"%@", NSStringFromSelector(_cmd));
    // If pageNumber == 1, then is a forum change, scroll to top.
    if (wasSuccessul && self.viewModelManager.pageNumber == 1) {
        [self.threadTableView scrollToTop];
    }
    [self updateTableView];
    [refreshControl endRefreshing];
    if (viewControllerNotInTransition)
        [progressView stopAnimating];
    if (!wasSuccessul) {
        [progressView showWarning];
    }
}

#pragma mark - self.refreshControl and download controls
-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:nil];
}

-(void)refreshThread:(id)sender{
    //reset to default page number
    [viewModelManager refresh];
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

    [numberButton setTitle:[NSString stringWithFormat:@"%ld", (long) viewModelManager.threads.count] forState:UIControlStateNormal];
    if (viewModelManager.threads.count <= 0) {
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
    czzForum *forum = [userInfo objectForKey:kPickedForum];
    if (forum){
        [self setSelectedForum:forum];
        [self refreshThread:self];
        //disallow image downloading if specified by remote settings
        shouldHideImageForThisForum = false;
        for (NSString *specifiedForum in settingsCentre.shouldHideImageInForums) {
            if ([specifiedForum isEqualToString:forum.name]) {
                shouldHideImageForThisForum = true;
                break;
            }
        }
    } else {
        [NSException raise:@"NOT A VALID FORUM" format:@""];
    }
}

-(void)setSelectedForum:(czzForum*)forum {
    viewModelManager.forum = forum;
    self.title = viewModelManager.forum.name;
    self.navigationItem.backBarButtonItem.title = self.title;
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

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"home_view_controller"];
}
@end
