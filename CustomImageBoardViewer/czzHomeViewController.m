//
//  czzViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzHomeViewController.h"
#import "UIViewController+ChildContainer.h"
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
#import "UIBarButtonItem+CIVLayout.h"
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

#import "CustomImageBoardViewer-Swift.h"

@interface czzHomeViewController() <UIAlertViewDelegate, SlideNavigationControllerDelegate>
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (assign, nonatomic) BOOL shouldHideImageForThisForum;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) czzAutoEndingRefreshControl* refreshControl;
@property (strong, nonatomic) UIBarButtonItem *numberBarButton;
@property (weak, nonatomic) UIView *postManagerViewContainer;
@property (strong, nonatomic) czzForum *selectedForum;
@property (strong, nonatomic) czzFavouriteManagerViewController *favouriteManagerViewController;
@property (strong, nonatomic) czzHomeTableViewManager *homeTableViewManager;
@property (strong, nonatomic) czzOnScreenImageManagerViewController *onScreenImageManagerViewController;
@property (strong, nonatomic) czzMiniThreadViewController *miniThreadView;
@property (strong, nonatomic) UIAlertView *confirmJumpToPageAlertView;
@end

@implementation czzHomeViewController

/// Layout constants carried over from the retired home scene.
static CGFloat const kHomeContainerSize = 60;
static CGFloat const kHomeContainerInset = 8;

- (void)loadView {
  UIView *rootView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  rootView.backgroundColor = [UIColor whiteColor];
  self.view = rootView;

  czzThreadTableView *tableView = [[czzThreadTableView alloc] initWithFrame:CGRectZero];
  tableView.translatesAutoresizingMaskIntoConstraints = NO;
  tableView.showsHorizontalScrollIndicator = NO;
  tableView.showsVerticalScrollIndicator = NO;
  tableView.alwaysBounceVertical = YES;
  [rootView addSubview:tableView];
  self.threadTableView = tableView;

  UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [tableView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
    [tableView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
    [tableView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
    [tableView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]
  ]];

  [self buildNavigationItems];
  [self buildFloatingContainers];
}

- (void)buildNavigationItems {
  self.navigationItem.title = @"A岛";

  UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(sideButtonAction:)];
  UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(moreInfoAction:)];
  self.navigationItem.leftBarButtonItems = @[menuButton, infoButton];
  self.forumListButton = menuButton;
  self.infoBarButton = infoButton;

  if (!self.numberBarButton) {
    self.numberBarButton = [[UIBarButtonItem alloc] initWithTitle:@"0/0"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(jumpAction:)];
  }
  self.navigationItem.rightBarButtonItem = self.numberBarButton;

  // The bottom toolbar carries the primary actions.
  UIBarButtonItem *(^flex)(void) = ^UIBarButtonItem *(void) {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  };
  UIBarButtonItem *jumpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"advance.png"] style:UIBarButtonItemStylePlain target:self action:@selector(jumpAction:)];
  self.jumpBarButtonItem = jumpButton;
  self.toolbarItems = @[
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"message.png"] style:UIBarButtonItemStylePlain target:self action:@selector(postAction:)],
    flex(),
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bookmark.png"] style:UIBarButtonItemStylePlain target:self action:@selector(bookmarkAction:)],
    flex(),
    jumpButton,
    flex(),
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsAction:)]
  ];
}

- (void)buildFloatingContainers {
  UIView *imageContainer = [[UIView alloc] init];
  imageContainer.translatesAutoresizingMaskIntoConstraints = NO;
  imageContainer.hidden = YES;
  [self.view addSubview:imageContainer];
  self.onScreenImageManagerViewContainer = imageContainer;

  UIView *postContainer = [[UIView alloc] init];
  postContainer.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:postContainer];
  self.postManagerViewContainer = postContainer;

  UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [postContainer.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-kHomeContainerInset],
    [postContainer.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-kHomeContainerInset],
    [postContainer.widthAnchor constraintEqualToConstant:kHomeContainerSize],
    [postContainer.heightAnchor constraintEqualToConstant:kHomeContainerSize],

    [imageContainer.trailingAnchor constraintEqualToAnchor:postContainer.trailingAnchor],
    [imageContainer.bottomAnchor constraintEqualToAnchor:postContainer.topAnchor constant:-kHomeContainerInset],
    [imageContainer.widthAnchor constraintEqualToConstant:kHomeContainerSize],
    [imageContainer.heightAnchor constraintEqualToConstant:kHomeContainerSize]
  ]];
}

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self civ_sanitizeBarButtonLayout];
    
    // Assign the data sources and delegates.
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
        [self civ_addChildViewController:self.onScreenImageManagerViewController
                             toContainer:self.onScreenImageManagerViewContainer];
    }
    // Post sender manager view controller.
    czzPostSenderManagerViewController *postSenderManagerViewController = [czzPostSenderManagerViewController new];
    [self civ_addChildViewController:postSenderManagerViewController
                         toContainer:self.postManagerViewContainer];
    // Register a notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forumPicked:)
                                                 name:kForumPickedNotification
                                               object:nil];
    
    [self.threadTableView addSubview:self.refreshControl];
    // Info bar button, must use custom view to allow badget value to be set.
    UIButton *customButton = [UIBarButtonItem civ_fixedSizeButtonWithImage:[UIImage imageNamed:@"info.png"]
                                                                    target:self
                                                                    action:@selector(moreInfoAction:)];
    [customButton setTitleColor:[UIColor whiteColor]
                       forState:UIControlStateHighlighted];
    self.infoBarButton.customView = customButton;
    
    // Always reload
    [self updateTableView];

    __weak typeof(self) weakSelf = self;
    [[czzForumManager sharedManager] updateForums:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.selectedForum) {
            return;
        }
        czzForum *firstForum = [czzForumManager sharedManager].forums.firstObject;
        if (!firstForum) {
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kForumPickedNotification
                                                            object:strongSelf
                                                          userInfo:@{kPickedForum: firstForum}];
    }];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self civ_sanitizeBarButtonLayout];
    // The navigation controller owns the toolbar it displays; a view controller's
    // own toolbarItems are only honoured when it hands them over.
    self.navigationController.toolbarItems = self.toolbarItems;
    
    self.threadTableView.backgroundColor = settingCentre.viewBackgroundColour;
    if (settingCentre.userDefNightyMode) {
        self.view.backgroundColor = UIColor.blackColor;
    } else {
        self.view.backgroundColor = UIColor.whiteColor;
    }
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

    // Load latest responses when user has no forum selected.
    if (!self.homeViewManager.forum && self.homeViewManager.latestResponses.displayableThreadCount == 0 && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        self.homeViewManager.isShowingLatestResponse = YES;
        [self.homeViewManager loadLatestResponse];
    }
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
        self.numberBarButton.customView = [[czzRoundButton alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    }
    // Give the amount number a title.
        [(czzRoundButton *)self.numberBarButton.customView setTitle:[NSString stringWithFormat:@"%ld", (long)self.homeViewManager.pageNumber] forState:UIControlStateNormal];
    NSMutableArray<NSString *>* titleComponents = @[].mutableCopy;
    NSString *title = self.homeViewManager.isShowingLatestResponse ? @"时间线" : self.homeViewManager.forum.name;
    if (title) {
        [titleComponents addObject:title];
    }
    NSString* host = [[NSURL alloc] initWithString:czzSettingsCentre.sharedInstance.activeHost].host;
    if (host) {
        [titleComponents addObject:host];
    }
    self.title = [titleComponents componentsJoinedByString:@" - "];
    self.navigationItem.backBarButtonItem.title = @"主页";
    [self.homeTableViewManager reloadData];
}

#pragma mark - ButtonActions
- (IBAction)tappedOnLoadPreviousPage:(UIButton *)sender {
  if (self.homeViewManager.threads.firstObject.pageNumber > 1) {
    [self.homeViewManager loadPreviousPage];
  } else {
    [self.homeViewManager refresh];
  }
  [self updateTableView];
}

- (IBAction)sideButtonAction:(id)sender {
    [[SlideNavigationController sharedInstance] toggleLeftMenu];
}

- (IBAction)postAction:(id)sender {
    [czzReplyUtil postToForum: self.homeViewManager.isShowingLatestResponse ? nil : self.homeViewManager.forum];
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
                
                [czzBannerNotificationUtil displayMessage:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)newPageNumber]
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
    czzNotificationCentreTableViewController *notificationCentreViewController = [czzNotificationCentreTableViewController new];
    [self.navigationController pushViewController:notificationCentreViewController animated:YES];
}

-(IBAction)moreInfoAction:(id)sender {
    if ([[(czzNavigationController*)self.navigationController notificationBannerViewController] shouldShow]) {
        [self openNotificationCentre];
    } else {
        czzMoreInfoViewController *moreInfoViewController = [czzMoreInfoViewController new];
        moreInfoViewController.forum = self.homeViewManager.forum;
        UINavigationController *navigationController = [[CustomAppearanceNavigationController alloc] initWithRootViewController:moreInfoViewController];
        navigationController.restorationIdentifier = NSStringFromClass([UINavigationController class]);
        [NavigationManager.delegate presentViewController:navigationController
                                                 animated:YES
                                               completion:nil];
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
  [self.homeViewManager refresh];
  [self updateTableView];
}

#pragma Notification handler - forumPicked
-(void)forumPicked:(NSNotification*)notification{
  NSDictionary *userInfo = notification.userInfo;
  czzForum *forum = [userInfo objectForKey:kPickedForum];
  if (forum){
    self.selectedForum = forum;
    self.homeViewManager.isShowingLatestResponse = NO;
    [self.homeViewManager refresh];
    //disallow image downloading if specified by remote settings
    self.shouldHideImageForThisForum = NO;
    for (NSString *specifiedForum in settingCentre.shouldHideImageInForums) {
      if ([specifiedForum isEqualToString:forum.name]) {
        self.shouldHideImageForThisForum = YES;
        break;
      }
    }
  } else if ([userInfo objectForKey:kPickedTimeline]) {
    self.homeViewManager.isShowingLatestResponse = YES;
    [self.homeViewManager refresh];
  } else {
    // Nothing usable in the payload: ignore it rather than raising, and skip the
    // reload because no forum was selected.
    DDLogDebug(@"Ignoring forum picked notification without a forum or timeline payload");
    return;
  }
  [self updateTableView];
}

#pragma mark - Setters
-(void)setSelectedForum:(czzForum *)selectedForum {
    _selectedForum = selectedForum;
    self.homeViewManager.forum = selectedForum;
}

#pragma mark - Transit

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.homeTableViewManager viewWillTransitionToSize];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end
