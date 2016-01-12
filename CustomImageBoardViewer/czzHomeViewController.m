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
#import "czzHomeViewManager.h"
#import "czzForumManager.h"
#import "czzHomeViewDelegate.h"
#import "czzThreadViewManager.h"
#import "czzForumsViewController.h"
#import "czzThreadTableView.h"
#import "czzSettingsViewController.h"
#import "czzRoundButton.h"
#import "czzFavouriteManagerViewController.h"

#import "czzHomeTableViewDataSource.h"

#import <CoreText/CoreText.h>


@interface czzHomeViewController() <UIAlertViewDelegate, UIStateRestoring>
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (assign, nonatomic) BOOL shouldHideImageForThisForum;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) UIRefreshControl* refreshControl;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *numberBarButton;
@property (assign, nonatomic) GSIndeterminateProgressView *progressView;
@property (strong, nonatomic) czzForum *selectedForum;
@property (strong, nonatomic) czzFavouriteManagerViewController *favouriteManagerViewController;
@property (strong, nonatomic) czzHomeTableViewDataSource *tableViewDataSource;
@property (strong, nonatomic) czzHomeViewDelegate *homeViewDelegate;
@property (strong, nonatomic) czzOnScreenImageManagerViewController *onScreenImageManagerViewController;
@end

@implementation czzHomeViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //assign a custom tableview data source
    self.threadTableView.dataSource = self.tableViewDataSource;
    self.threadTableView.delegate = self.homeViewDelegate;
    self.tableViewDataSource.tableViewDelegate = self.homeViewDelegate;
    
    // Load data into tableview
    [self updateTableView];
    if (!CGPointEqualToPoint(CGPointZero, self.homeViewManager.currentOffSet)) {
        [self.threadTableView setContentOffset:self.homeViewManager.currentOffSet animated:NO];
    }
    // Set the currentOffSet back to zero
    self.homeViewManager.currentOffSet = CGPointZero;

    // Configure the view deck controller with half size and tap to close mode
    self.viewDeckController.leftSize = self.view.frame.size.width/4;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;

    // On screen image manager view controller
    if (!self.onScreenImageManagerViewController) {
        self.onScreenImageManagerViewController = [czzOnScreenImageManagerViewController new];
        self.onScreenImageManagerViewController.delegate = self.homeViewDelegate;
        [self addChildViewController:self.onScreenImageManagerViewController];
        [self.onScreenImageManagerViewContainer addSubview:self.onScreenImageManagerViewController.view];
    }
    // Register a notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forumPicked:)
                                                 name:kForumPickedNotification
                                               object:nil];
    
    [self.threadTableView addSubview:self.refreshControl];
    // Info bar button, must use custom view to allow badget value to be set.
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [customButton setImage:[[UIImage imageNamed:@"info.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                  forState:UIControlStateNormal];
    [customButton setTitleColor:[UIColor whiteColor]
                       forState:UIControlStateHighlighted];
    customButton.frame = CGRectMake(0, 0, 44, 44);
    [customButton addTarget:self
                     action:@selector(moreInfoAction:)
           forControlEvents:UIControlEventTouchUpInside];
    self.infoBarButton.customView = customButton;
    
    // Always reload
    [self updateTableView];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    self.threadTableView.backgroundColor = settingCentre.viewBackgroundColour;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
    
    // Add badget number to infoBarButton if necessary.
    if ([[(czzNavigationController*)self.navigationController notificationBannerViewController] shouldShow]) {
        self.infoBarButton.badgeValue = @"1";
    } else {
        self.infoBarButton.badgeValue = nil;
    }

    // Select a random forum after a certain period of inactivity.
    NSTimeInterval delayTime = 4.0;
#ifdef DEBUG
    delayTime = 9999;
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.homeViewManager.forum) {
            if ([czzForumManager sharedManager].forums.count > 0)
            {
                [AppDelegate.window makeToast:@"用户没有选择板块，随机选择……"];
                @try {
                    int randomIndex = rand() % [czzForumManager sharedManager].forums.count;
                    [self.homeViewManager setForum:[[czzForumManager sharedManager].forums objectAtIndex:randomIndex]];
                    [self refreshThread:self];
                }
                @catch (NSException *exception) {
                    
                }
            }
        }
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.refreshControl endRefreshing];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
}

/*
 This method would update the contents related to the table view
 */
-(void)updateTableView {
    // Update bar buttons.
    if (!self.numberBarButton.customView) {
        self.numberBarButton.customView = [[czzRoundButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    }
    // Give the amount number a title.
    [(czzRoundButton *)self.numberBarButton.customView setTitle:[NSString stringWithFormat:@"%ld", (long) self.homeViewManager.threads.count] forState:UIControlStateNormal];
    // Other data
    self.title = self.homeViewManager.forum.name;
    self.navigationItem.backBarButtonItem.title = self.title;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.threadTableView reloadData];
    });
}

#pragma mark - State perserving
- (NSString*)saveCurrentState {
    self.homeViewManager.currentOffSet = self.threadTableView.contentOffset;
    return [self.homeViewManager saveCurrentState];
}

#pragma mark - ButtonActions
- (IBAction)sideButtonAction:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
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
    // Present favourite manager modally.
    [self.navigationController pushViewController:[czzFavouriteManagerViewController new] animated:YES];
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
            [self.homeViewManager removeAll];
            [self updateTableView];
            [self.refreshControl beginRefreshing];
            [self.homeViewManager loadMoreThreads:newPageNumber];

            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)self.homeViewManager.pageNumber]];
        } else {
            [[AppDelegate window] makeToast:@"页码无效..."];
        }
    }
}

#pragma mark - more action and commands

- (IBAction)reloadDataAction:(id)sender {
    self.homeViewDelegate.cachedVerticalHeights = self.homeViewDelegate.cachedHorizontalHeights = nil;
    [self.threadTableView reloadData];
}


-(void)openSettingsPanel{
    czzSettingsViewController *settingsViewController = [czzSettingsViewController new];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

-(void)openNotificationCentre {
    czzNotificationCentreTableViewController *notificationCentreViewController = [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [self.navigationController pushViewController:notificationCentreViewController animated:YES];
}

-(void)newPost{
    if (self.homeViewManager.forum){
        czzPostViewController *newPostViewController = [czzPostViewController new];
        newPostViewController.forum = self.homeViewManager.forum;
        newPostViewController.postMode = postViewControllerModeNew;
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:newPostViewController] animated:YES completion:nil];
    } else {
        [[AppDelegate window] makeToast:@"未选定一个版块" duration:1.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}

-(IBAction)moreInfoAction:(id)sender {
    if ([[(czzNavigationController*)self.navigationController notificationBannerViewController] shouldShow]) {
        [self openNotificationCentre];
    } else {
        czzMoreInfoViewController *moreInfoViewController = [czzMoreInfoViewController new];
        moreInfoViewController.forum = self.homeViewManager.forum;
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:moreInfoViewController] animated:YES completion:nil];
    }
}

#pragma mark - Getters
-(czzHomeViewManager *)homeViewManager {
    [czzHomeViewManager sharedManager].delegate = self;
    return [czzHomeViewManager sharedManager];
}

-(GSIndeterminateProgressView *)progressView {
    if (!_progressView) {
        _progressView = [(czzNavigationController*) self.navigationController progressView];
    }
    return _progressView;
}

-(UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self
                            action:@selector(dragOnRefreshControlAction:)
                  forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

-(czzHomeTableViewDataSource *)tableViewDataSource {
    if (!_tableViewDataSource) {
        _tableViewDataSource = [czzHomeTableViewDataSource initWithViewManager:self.homeViewManager andTableView:self.threadTableView];
    }
    return _tableViewDataSource;
}

-(czzHomeViewDelegate *)homeViewDelegate {
    if (!_homeViewDelegate) {
        _homeViewDelegate = [czzHomeViewDelegate initWithViewManager:self.homeViewManager andTableView:self.threadTableView];
    }
    return _homeViewDelegate;
}



- (void)homeViewManagerWantsToReload:(czzHomeViewManager *)manager {
    if (manager.threads.count) {
        [self updateTableView];
    }
}

-(void)homeViewManager:(czzHomeViewManager *)homeViewManager downloadSuccessful:(BOOL)wasSuccessful {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (!wasSuccessful && !NavigationManager.isInTransition) {
        [self.refreshControl endRefreshing];
        [self.progressView stopAnimating];
        [self.progressView showWarning];
    }
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
}

-(void)homeViewManagerBeginsDownloading:(czzHomeViewManager *)homeViewManager {
    if (!self.progressView.isAnimating)
        [self.progressView startAnimating];
    
}

-(void)homeViewManager:(czzHomeViewManager *)list threadListProcessed:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    // If pageNumber == 1, then is a forum change, scroll to top.
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [self.refreshControl endRefreshing];
        if (wasSuccessul && self.homeViewManager.pageNumber == 1) {
            [self.threadTableView scrollToTop:NO];
            self.homeViewDelegate.cachedHorizontalHeights = self.homeViewDelegate.cachedVerticalHeights = nil;
        }
        [self updateTableView];

        // If is in transition, is better not do anything.
        if (!NavigationManager.isInTransition)
            [self.progressView stopAnimating];
        if (!wasSuccessul) {
            [self.progressView showWarning];
        }
    }];
}

#pragma mark - self.refreshControl and download controls
-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:nil];
}

-(void)refreshThread:(id)sender{
    //reset to default page number
    [self.homeViewManager refresh];
}

#pragma Notification handler - forumPicked
-(void)forumPicked:(NSNotification*)notification{
    NSDictionary *userInfo = notification.userInfo;
    czzForum *forum = [userInfo objectForKey:kPickedForum];
    if (forum){
        self.selectedForum = forum;
        [self refreshThread:self];
        //disallow image downloading if specified by remote settings
        self.shouldHideImageForThisForum = NO;
        for (NSString *specifiedForum in settingCentre.shouldHideImageInForums) {
            if ([specifiedForum isEqualToString:forum.name]) {
                self.shouldHideImageForThisForum = YES;
                break;
            }
        }
    } else {
        [NSException raise:@"NOT A VALID FORUM" format:@""];
    }
}

#pragma mark - Setters
-(void)setSelectedForum:(czzForum *)selectedForum {
    _selectedForum = selectedForum;
    self.homeViewManager.forum = selectedForum;
    if (selectedForum) {
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Home"
                                                                                            action:@"Pick Forum"
                                                                                             label:selectedForum.name
                                                                                             value:@1] build]];
    }
}

#pragma mark - rotation events
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self updateTableView];
}

#pragma mark - pause / restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"home_view_controller"];
}
@end
