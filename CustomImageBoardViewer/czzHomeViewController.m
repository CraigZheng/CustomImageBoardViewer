//
//  czzViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzHomeViewController.h"
#import "SMXMLDocument.h"
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
#import "czzHomeViewManager.h"
#import "czzForumManager.h"
#import "czzHomeTableViewManager.h"
#import "czzThreadViewManager.h"
#import "czzForumsViewController.h"
#import "czzThreadTableView.h"
#import "czzSettingsViewController.h"
#import "czzRoundButton.h"
#import "czzFavouriteManagerViewController.h"
#import "czzHomeTableViewManager.h"
#import "czzReplyUtil.h"
#import "czzPostSenderManagerViewController.h"
#import "czzMiniThreadViewController.h"
#import "czzBannerNotificationUtil.h"
#import "czzAutoEndingRefreshControl.h"

#import <CoreText/CoreText.h>


@interface czzHomeViewController() <UIAlertViewDelegate, UIStateRestoring, SlideNavigationControllerDelegate>
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (assign, nonatomic) BOOL shouldHideImageForThisForum;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) czzAutoEndingRefreshControl* refreshControl;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *numberBarButton;
@property (weak, nonatomic) IBOutlet UIView *postManagerViewContainer;
@property (strong, nonatomic) czzForum *selectedForum;
@property (strong, nonatomic) czzFavouriteManagerViewController *favouriteManagerViewController;
@property (strong, nonatomic) czzHomeTableViewManager *homeTableViewManager;
@property (strong, nonatomic) czzOnScreenImageManagerViewController *onScreenImageManagerViewController;
@property (strong, nonatomic) czzMiniThreadViewController *miniThreadView;
@property (strong, nonatomic) UIAlertView *confirmJumpToPageAlertView;
@end

@implementation czzHomeViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //assign a custom tableview data source
    self.threadTableView.dataSource = self.homeTableViewManager;
    self.threadTableView.delegate = self.homeTableViewManager;
    
    // Load data into tableview
    [self updateTableView];
    if (!CGPointEqualToPoint(CGPointZero, self.homeViewManager.currentOffSet)) {
        [self.threadTableView setContentOffset:self.homeViewManager.currentOffSet animated:NO];
    }
    // Set the currentOffSet back to zero
    self.homeViewManager.currentOffSet = CGPointZero;
    // On screen image manager view controller
    if (!self.onScreenImageManagerViewController) {
        self.onScreenImageManagerViewController = [czzOnScreenImageManagerViewController new];
        [self addChildViewController:self.onScreenImageManagerViewController];
        [self.onScreenImageManagerViewContainer addSubview:self.onScreenImageManagerViewController.view];
    }
    // Post sender manager view controller.
    czzPostSenderManagerViewController *postSenderManagerViewController = [czzPostSenderManagerViewController new];
    [self addChildViewController:postSenderManagerViewController];
    [self.postManagerViewContainer addSubview:postSenderManagerViewController.view];
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
    self.onScreenImageManagerViewContainer.hidden = !settingCentre.shouldShowImageManagerButton;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.progressView viewDidAppear];
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
                [czzBannerNotificationUtil displayMessage:@"用户没有选择板块，随机选择……" position:BannerNotificationPositionTop];
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

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.progressView viewDidDisapper];
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
    [self.homeTableViewManager reloadData];
}

#pragma mark - State perserving
- (NSString*)saveCurrentState {
    self.homeViewManager.currentOffSet = self.threadTableView.contentOffset;
    return [self.homeViewManager saveCurrentState];
}

#pragma mark - ButtonActions
- (IBAction)sideButtonAction:(id)sender {
    [[SlideNavigationController sharedInstance] toggleLeftMenu];
}

- (IBAction)postAction:(id)sender {
    [czzReplyUtil postToForum:self.homeViewManager.forum];
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
    self.confirmJumpToPageAlertView = alertView;
    [self.confirmJumpToPageAlertView show];
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
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView == self.confirmJumpToPageAlertView) {
            NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
            if (newPageNumber > 0){
                
                //clear threads and ready to accept new threads
                [self.homeViewManager removeAll];
                [self updateTableView];
                [self.homeViewManager loadMoreThreads:newPageNumber];
                
                [czzBannerNotificationUtil displayMessage:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)self.homeViewManager.pageNumber]
                                                 position:BannerNotificationPositionTop];
            } else {
                [czzBannerNotificationUtil displayMessage:@"页码无效..."
                                                 position:BannerNotificationPositionTop];
            }
        }
    }
}

#pragma mark - UI actions and commands.

-(void)openSettingsPanel{
    czzSettingsViewController *settingsViewController = [czzSettingsViewController new];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

-(void)openNotificationCentre {
    czzNotificationCentreTableViewController *notificationCentreViewController = [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [self.navigationController pushViewController:notificationCentreViewController animated:YES];
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

-(czzAutoEndingRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[czzAutoEndingRefreshControl alloc] init];
        [_refreshControl addTarget:self
                            action:@selector(dragOnRefreshControlAction:)
                  forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

-(czzHomeTableViewManager *)homeTableViewManager {
    if (!_homeTableViewManager) {
        _homeTableViewManager = [czzHomeTableViewManager new];
        _homeTableViewManager.homeViewManager = self.homeViewManager;
        _homeTableViewManager.homeTableView = self.threadTableView;
    }
    return _homeTableViewManager;
}

#pragma mark - czzHomeViewManagerDelegate

- (void)homeViewManager:(czzHomeViewManager *)homeViewManager wantsToShowContentForThread:(czzThread *)thread {
    self.miniThreadView = [czzMiniThreadViewController new];
    self.miniThreadView.myThread = thread;
    [self.miniThreadView modalShow];
}

- (void)homeViewManagerWantsToReload:(czzHomeViewManager *)manager {
    if (manager.threads.count) {
        [self updateTableView];
    }
}

-(void)homeViewManager:(czzHomeViewManager *)homeViewManager downloadSuccessful:(BOOL)wasSuccessful {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
    if (!wasSuccessful) {
        [self showWarning];
    }
}

-(void)viewManagerDownloadStateChanged:(czzHomeViewManager *)homeViewManager {
    if (homeViewManager.isDownloading) {
        [self startLoading];
    } else {
        [self stopLoading];
    }
}

-(void)homeViewManager:(czzHomeViewManager *)list threadListProcessed:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    DDLogDebug(@"%@", NSStringFromSelector(_cmd));
    // If pageNumber == 1, then is a forum change, scroll to top.
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        if (wasSuccessul && self.homeViewManager.pageNumber == 1) {
            [self.threadTableView scrollToTop:NO];
        }
        [self updateTableView];
        // Show warning.
        if (!wasSuccessul) {
            [self showWarning];
        }
    }];
}

#pragma mark - SlideOutNavigationControllerDelegate

- (BOOL)slideNavigationControllerShouldDisplayLeftMenu {
    return YES;
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

#pragma mark - Rotation events.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.homeTableViewManager viewWillTransitionToSize:size
                              withTransitionCoordinator:coordinator];
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
