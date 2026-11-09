    //
//  czzThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadViewController.h"
#import "UIViewController+ChildContainer.h"
#import "czzThread.h"
#import "czzBannerNotificationUtil.h"
#import "SMXMLDocument.h"
#import "czzImageCacheManager.h"
#import "czzImageViewerUtil.h"
#import "czzAppDelegate.h"
#import "czzHomeViewController.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadRefButton.h"
#import "PartialTransparentView.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzMiniThreadViewController.h"
#import "czzNavigationController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "czzThreadTableViewManager.h"
#import "czzFavouriteManager.h"
#import "czzRoundButton.h"
#import "czzPostSenderManagerViewController.h"
#import "czzReplyUtil.h"
#import "czzAutoEndingRefreshControl.h"
#import "czzThreadViewManager.h"
#import "UIBarButtonItem+CIVLayout.h"

#import "UIImage+animatedGIF.h"

#import "CustomImageBoardViewer-Swift.h"


@interface czzThreadViewController ()<UIAlertViewDelegate, czzThreadViewManagerDelegate, czzMiniThreadViewControllerDelegate>
@property (strong, nonatomic) NSIndexPath *selectedIndex;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
@property (assign, nonatomic) BOOL shouldDisplayQuickScrollCommand;
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) UIViewController *rightViewController;
@property (strong, nonatomic) UIViewController *topViewController;
@property (strong, nonatomic) czzMiniThreadViewController *miniThreadView;
@property (strong, nonatomic) czzAutoEndingRefreshControl *refreshControl;
@property (strong, nonatomic) czzThreadTableViewManager *threadTableViewManager;
@property (strong, nonatomic) czzOnScreenImageManagerViewController *onScreenImageManagerViewController;
@property (weak, nonatomic) IBOutlet UIView *postSenderViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *massiveDownloadButtonHeightConstraint;
@property (strong, nonatomic) UIAlertView *confirmMassiveDownloadAlertView;
@property (strong, nonatomic) UIAlertView *confirmCancelMassiveDownloadAlertView;
@property (strong, nonatomic) UIAlertView *confirmJumpToPageAlertView;
@property (weak, nonatomic) IBOutlet UIImageView *massiveDownloadIndicatorImageView;
@property (weak, nonatomic) IBOutlet UISwitch *poOnlySwitch;
@property (weak, nonatomic) IBOutlet UIButton *massiveDownloadButton;
@property (strong, nonatomic) czzRoundButton *pageNumberButton;
@property (strong, nonatomic) czzThreadViewManager *threadViewManager;
@property (strong, nonatomic) NSObject *observation;
@property (assign, nonatomic)BOOL poOnlyMode;
@end

@implementation czzThreadViewController
@synthesize selectedIndex;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize rightViewController;
@synthesize topViewController;
@synthesize miniThreadView;
@synthesize imageViewerUtil;
@synthesize onScreenImageManagerViewContainer;
@synthesize shouldRestoreContentOffset;

/// Layout constants carried over from the retired thread view scene.
static CGFloat const kThreadContainerSize = 60;
static CGFloat const kThreadContainerInset = 8;
static CGFloat const kThreadContainerTrailingInset = 20;
static CGFloat const kDownloadButtonWidth = 40;
static CGFloat const kDownloadTrailingInset = 30;
static CGFloat const kDownloadBottomInset = 12;

- (void)loadView {
  UIView *rootView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  rootView.backgroundColor = [UIColor whiteColor];
  self.view = rootView;

  czzThreadTableView *tableView = [[czzThreadTableView alloc] initWithFrame:CGRectZero];
  tableView.translatesAutoresizingMaskIntoConstraints = NO;
  [rootView addSubview:tableView];
  self.threadTableView = tableView;

  UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [tableView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
    [tableView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
    [tableView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
    [tableView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor]
  ]];

  [self buildToolbarItems];
  [self buildFloatingContainers];
}

- (void)buildToolbarItems {
  UIBarButtonItem *(^flex)(void) = ^UIBarButtonItem *(void) {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  };

  UIBarButtonItem *reply = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reply.png"] style:UIBarButtonItemStylePlain target:self action:@selector(replyAction:)];
  UIBarButtonItem *star = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star.png"] style:UIBarButtonItemStylePlain target:self action:@selector(starAction:)];
  UIBarButtonItem *upload = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"upload.png"] style:UIBarButtonItemStylePlain target:self action:@selector(shareAction:)];
  // The advance button doubles as the page counter, so there is one control for
  // both: it shows the current page and jumps when tapped.
  czzRoundButton *pageButton = [[czzRoundButton alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
  pageButton.titleLabel.font = [UIFont systemFontOfSize:11];
  // A bar item wrapping a custom view forwards nothing itself: the button inside
  // has to carry the action.
  [pageButton addTarget:self action:@selector(jumpAction:) forControlEvents:UIControlEventTouchUpInside];
  self.pageNumberButton = pageButton;
  // Keep a strong reference before building the array: a weak property would read
  // back nil here because nothing else retains the item yet.
  UIBarButtonItem *advance = [[UIBarButtonItem alloc] initWithCustomView:pageButton];
  self.jumpBarButtonItem = advance;
  self.toolbarItems = @[reply, flex(), star, flex(), upload, flex(), advance];
  self.starButton = star;

  UISwitch *poSwitch = [[UISwitch alloc] init];
  [poSwitch addTarget:self action:@selector(togglePOOnlyModeAction:) forControlEvents:UIControlEventValueChanged];
  self.poOnlySwitch = poSwitch;

  UILabel *poLabel = [[UILabel alloc] init];
  poLabel.text = @"只看PO";
  poLabel.font = [UIFont systemFontOfSize:17];
  [poLabel sizeToFit];
  poLabel.frame = CGRectMake(0, 6, CGRectGetWidth(poLabel.frame), CGRectGetHeight(poLabel.frame));

  poSwitch.frame = CGRectMake(CGRectGetMaxX(poLabel.frame) + 8, 0, CGRectGetWidth(poSwitch.frame), 33);
  UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
      CGRectGetMaxX(poSwitch.frame), 33)];
  poSwitch.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  [switchContainer addSubview:poLabel];
  [switchContainer addSubview:poSwitch];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:switchContainer];

}

- (void)buildFloatingContainers {
  // Layout matches the retired scene: the containers stack bottom-up above the
  // massive download button, which is collapsed to zero height until needed.
  UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
  downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
  [downloadButton setImage:[UIImage imageNamed:@"download.png"] forState:UIControlStateNormal];
  [downloadButton addTarget:self action:@selector(massiveDownloadAction:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:downloadButton];
  self.massiveDownloadButton = downloadButton;

  UIImageView *indicator = [[UIImageView alloc] init];
  indicator.translatesAutoresizingMaskIntoConstraints = NO;
  indicator.contentMode = UIViewContentModeScaleAspectFit;
  [downloadButton addSubview:indicator];
  self.massiveDownloadIndicatorImageView = indicator;

  UIView *imageContainer = [[UIView alloc] init];
  imageContainer.translatesAutoresizingMaskIntoConstraints = NO;
  imageContainer.hidden = YES;
  [self.view addSubview:imageContainer];
  self.onScreenImageManagerViewContainer = imageContainer;

  UIView *postContainer = [[UIView alloc] init];
  postContainer.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:postContainer];
  self.postSenderViewContainer = postContainer;

  UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
  NSLayoutConstraint *downloadHeight = [downloadButton.heightAnchor constraintEqualToConstant:0];
  downloadHeight.active = YES;
  self.massiveDownloadButtonHeightConstraint = downloadHeight;

  [NSLayoutConstraint activateConstraints:@[
    // The download button is narrower than the containers and sits further in
    // from the trailing edge, exactly as the retired scene had it.
    [safeArea.trailingAnchor constraintEqualToAnchor:downloadButton.trailingAnchor constant:kDownloadTrailingInset],
    [safeArea.bottomAnchor constraintEqualToAnchor:downloadButton.bottomAnchor constant:kDownloadBottomInset],
    [downloadButton.widthAnchor constraintEqualToConstant:kDownloadButtonWidth],

    [indicator.centerXAnchor constraintEqualToAnchor:downloadButton.centerXAnchor],
    [indicator.centerYAnchor constraintEqualToAnchor:downloadButton.centerYAnchor],
    [indicator.widthAnchor constraintEqualToAnchor:downloadButton.widthAnchor],
    [indicator.heightAnchor constraintEqualToAnchor:downloadButton.heightAnchor],

    // The container stack anchors to the download button, not the safe area.
    [safeArea.trailingAnchor constraintEqualToAnchor:imageContainer.trailingAnchor constant:kThreadContainerTrailingInset],
    [imageContainer.bottomAnchor constraintEqualToAnchor:downloadButton.topAnchor constant:-kThreadContainerInset],
    [imageContainer.widthAnchor constraintEqualToConstant:kThreadContainerSize],
    [imageContainer.heightAnchor constraintEqualToConstant:kThreadContainerSize],

    [postContainer.leadingAnchor constraintEqualToAnchor:imageContainer.leadingAnchor],
    [postContainer.bottomAnchor constraintEqualToAnchor:imageContainer.topAnchor constant:-kThreadContainerInset],
    [postContainer.widthAnchor constraintEqualToConstant:kThreadContainerSize],
    [postContainer.heightAnchor constraintEqualToConstant:kThreadContainerSize],

    [imageContainer.topAnchor constraintGreaterThanOrEqualToAnchor:safeArea.topAnchor constant:20]
  ]];
}

#pragma mark - view controller life cycle.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self civ_sanitizeBarButtonLayout];
    // If self.thread is not ready, the whole view controller is not ready.
    if (self.thread) {
        [self commonInit];
    }
    __weak typeof(self) weakSelf = self;
    self.observation = [NSNotificationCenter.defaultCenter addObserverForName:settingsChangedNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf.threadTableView reloadData];
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self civ_sanitizeBarButtonLayout];
    // The navigation controller owns the toolbar it displays; a view controller's
    // own toolbarItems are only honoured when it hands them over.
    self.navigationController.toolbarItems = self.toolbarItems;
    // UI appearance.
    self.threadTableView.backgroundColor = [settingCentre viewBackgroundColour];
    if (settingCentre.userDefNightyMode) {
        self.view.backgroundColor = UIColor.blackColor;
    } else {
        self.view.backgroundColor = UIColor.whiteColor;
    }
    self.onScreenImageManagerViewContainer.hidden = !settingCentre.shouldShowImageManagerButton;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.progressView viewDidAppear];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.progressView viewDidDisapper];
}

- (void)commonInit {
  self.threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:self.thread andForum:nil];
  self.threadViewManager.delegate = self;
  if (settingCentre.userDefRecordPageNumber) {
    [self.threadViewManager restorePreviousState];
  }
  // The manager for the table view.
  self.threadTableView.dataSource = self.threadTableViewManager;
  self.threadTableView.delegate = self.threadTableViewManager;
  
  // Thumbnail folder
  thumbnailFolder = [czzAppDelegate thumbnailFolder];
  imageViewerUtil = [czzImageViewerUtil new];
  // On screen image manager view controller
  if (!self.onScreenImageManagerViewController) {
    self.onScreenImageManagerViewController = [czzOnScreenImageManagerViewController new];
    self.onScreenImageManagerViewController.delegate = self.threadTableViewManager;
    [self civ_addChildViewController:self.onScreenImageManagerViewController
                         toContainer:self.onScreenImageManagerViewContainer];
  }
  // Post sender manager view controller.
  czzPostSenderManagerViewController *postSenderManagerViewController = [czzPostSenderManagerViewController new];
  [self civ_addChildViewController:postSenderManagerViewController
                       toContainer:self.postSenderViewContainer];
  
  //add the UIRefreshControl to uitableview
  self.refreshControl = [[czzAutoEndingRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
  [self.threadTableView addSubview: self.refreshControl];
    
  if (NavigationManager.isInTransition) {
    NavigationManager.pushAnimationCompletionHandler = ^{
      [self.threadViewManager loadMoreThreads:self.threadViewManager.pageNumber];
    };
  } else {
    [self.threadViewManager loadMoreThreads:self.threadViewManager.pageNumber];
  }
}

- (void)dealloc {
    // Avoid calling deacllocated data source and delegate.
    self.threadTableView.dataSource = nil;
    self.threadTableView.delegate = nil;
    [self.threadViewManager stopAllOperation];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Cache downloaded data into disk.
    [self.threadViewManager saveCurrentState];
}


/*
 This method would update the contents related to the table view
 */
-(void)updateTableView {
  // Update bar buttons. The advance button shows the current page number.
  [self.pageNumberButton setTitle:[NSString stringWithFormat:@"%ld", (long)self.threadViewManager.pageNumber]
                         forState:UIControlStateNormal];
  
  // Star button image - on or off. civ_sanitizeBarButtonLayout replaces the bar
  // item's image with a custom view and nils the item's image, so the glyph has
  // to be set on the button inside the custom view.
  UIImage *starImage = [favouriteManager isThreadFavourited:self.threadViewManager.parentThread]
      ? [UIImage imageNamed:@"solid_star.png"]
      : [UIImage imageNamed:@"star.png"];
  if ([self.starButton.customView isKindOfClass:[UIButton class]]) {
    [(UIButton *)self.starButton.customView setImage:starImage forState:UIControlStateNormal];
  } else {
    self.starButton.image = starImage;
  }
  NSString *userID;
  if ([self.poOnlySwitch isOn]) {
    userID = self.threadViewManager.parentThread.UID;
  } else {
    userID = NULL;
  }
  [self.threadViewManager setOnlyShowUserID:userID];
  [self.threadTableViewManager reloadData];
}

#pragma mark - Getters
- (czzThreadTableViewManager *)threadTableViewManager {
    if (!_threadTableViewManager) {
        _threadTableViewManager = [czzThreadTableViewManager new];
        _threadTableViewManager.threadViewManager = self.threadViewManager;
        _threadTableViewManager.threadTableView = self.threadTableView;
    }
    return _threadTableViewManager;
}

#pragma mark - setter
-(void)setThreadViewManager:(czzThreadViewManager *)viewManager {
    _threadViewManager = viewManager;
    if (viewManager) {
        // Update bar buttons. The advance button shows the loaded thread count until
        // a page number is known, and is hidden when there is nothing to show.
        NSInteger loadedCount = self.threadViewManager.threads.count;
        NSString *title = loadedCount > 0
            ? [NSString stringWithFormat:@"%ld", (long)loadedCount]
            : nil;
        [self.pageNumberButton setTitle:title forState:UIControlStateNormal];
        self.jumpBarButtonItem.enabled = loadedCount > 0;
        // Hide the massive download button at first, then show it with animation.
        // Show it only when the total pages is still 3 or more pages away from the current page number.
        // lastObject is nil until the first page arrives; treat that as no button.
        NSInteger currentPage = viewManager.threads.lastObject.pageNumber;
        NSInteger remainingPages = currentPage > 0 ? viewManager.totalPages - currentPage : 0;
        if (!self.massiveDownloadButtonHeightConstraint.constant && remainingPages >= 3) {
            self.massiveDownloadButtonHeightConstraint.constant = 40;
            [UIView animateWithDuration:0.2 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
        // Else, if the massive download button is showing and view manager has reached all of its pages.
        else if (self.massiveDownloadButtonHeightConstraint.constant && remainingPages <= 0) {
            self.massiveDownloadButtonHeightConstraint.constant = 0;
            [UIView animateWithDuration:0.2 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }
}

-(void)dragOnRefreshControlAction:(id)sender{
  [self refreshThread:self];
  [self updateTableView];
}

#pragma mark - jump to and download controls
-(void)PromptForJumpToPage{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %ld/%ld", (long) self.threadViewManager.threads.lastObject.pageNumber, (long) self.threadViewManager.totalPages] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
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

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // If user did not tap on the cancel button.
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView == self.confirmMassiveDownloadAlertView) {
            // If the incoming alertView is the confirm massive download alert view, start loadAll action.
            [self.threadViewManager loadAll];
        } else if (alertView == self.confirmJumpToPageAlertView) {
            // If user wants to jump to a specific page number, verify that user enters a valid page number.
            NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
            if (newPageNumber > 0){
                [self.threadViewManager jumpToPage:newPageNumber];
                [self updateTableView];
                [czzBannerNotificationUtil displayMessage:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)newPageNumber]
                                                 position:BannerNotificationPositionTop];
            } else {
                [czzBannerNotificationUtil displayMessage:@"页码无效..."
                                                 position:BannerNotificationPositionTop];
            }
        } else if (alertView == self.confirmCancelMassiveDownloadAlertView) {
            [self.threadViewManager stopAllOperation];
        }
    }
}

-(void)refreshThread:(id)sender{
    [self.threadViewManager refresh];
    [self updateTableView];
}

#pragma mark - czzThreadViewManagerDelegate
- (void)homeViewManager:(czzHomeViewManager *)homeViewManager wantsToShowContentForThread:(czzThread *)thread {
    self.miniThreadView = [czzMiniThreadViewController new];
    self.miniThreadView.myThread = thread;
    self.miniThreadView.delegate = self;
    [self.miniThreadView modalShow];
}

- (void)homeViewManager:(czzHomeViewManager *)threadViewManager wantsToScrollToContentOffset:(CGPoint)offset {
    // If not CGPointZero
    if (!CGPointEqualToPoint(CGPointZero, offset) && self.threadTableView) {
        self.threadTableView.contentOffset = offset;
    }
}

- (void)homeViewManagerWantsToReload:(czzHomeViewManager *)manager {
    if (manager.threads.count) {
        [self updateTableView];
    }
}

-(void)viewManagerDownloadStateChanged:(czzHomeViewManager *)homeViewManager {
    if (homeViewManager.isDownloading) {
        [self startLoading];
    } else {
        [self stopLoading];
    }
    // Massive downloading - set images for the massive download indicator.
    if (self.threadViewManager.isMassiveDownloading) {
        if (!self.massiveDownloadIndicatorImageView.image)
            self.massiveDownloadIndicatorImageView.image = [UIImage animatedImageWithAnimatedGIFURL:[[NSBundle mainBundle] URLForResource:@"loading_bar_dot"
                                                                                                                        withExtension:@"gif"]];
    } else {
        self.massiveDownloadIndicatorImageView.image = nil;
    }
}

-(void)homeViewManager:(czzHomeViewManager *)threadViewManager downloadSuccessful:(BOOL)wasSuccessful {
    if (!wasSuccessful) {
        [self showWarning];
    }
}

-(void)homeViewManager:(czzHomeViewManager *)threadViewManager threadContentProcessed:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    if (wasSuccessul) {
        if (newThreads.count) {
            self.threadViewManager = (czzThreadViewManager*)threadViewManager;
        }
    } else {
        [self showWarning];
    }
    [self updateTableView];
    // Reset the lastCellType back to default.
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
}

- (void)viewManagerContinousDownloadUpdated:(czzThreadViewManager *)viewManager {
    // A download of a page is completed, display it on screen.
    self.threadViewManager = viewManager;
    [self updateTableView];
}

- (void)viewManager:(czzThreadViewManager *)viewManager continousDownloadCompleted:(BOOL)success {
    // All threads downloaded, the handling of this event would be the same as a single page downloader event.
    [self homeViewManager:viewManager
   threadContentProcessed:success
               newThreads:viewManager.lastBatchOfThreads
               allThreads:viewManager.threads];
}

#pragma mark - UI button actions
- (IBAction)tappedOnLoadPreviousPage:(UIButton *)sender {
  if (self.threadViewManager.threads.count >= 2 && self.threadViewManager.threads[1].pageNumber > 1) {
    [self.threadViewManager loadPreviousPage];
  } else {
    [self refreshThread:self];
  }
  [self updateTableView];
}

- (IBAction)massiveDownloadAction:(id)sender {
    if (self.threadViewManager.isMassiveDownloading) {
        // Stop massive download.
        self.confirmCancelMassiveDownloadAlertView = [[UIAlertView alloc] initWithTitle:@"取消一键到底!"
                                                                                message:[NSString stringWithFormat:@"是否取消一键到底?"]
                                                                               delegate:self
                                                                      cancelButtonTitle:@"算了"
                                                                      otherButtonTitles:@"确定", nil];
        [self.confirmCancelMassiveDownloadAlertView show];
    } else if (self.threadViewManager.totalPages - self.threadViewManager.threads.lastObject.pageNumber >= 1){
        // Start massive download.
        self.confirmMassiveDownloadAlertView = [[UIAlertView alloc] initWithTitle:@"一键到底!"
                                                                          message:[NSString stringWithFormat:@"将加载%ld页内容,请确认!",
                                                                                   (long)(self.threadViewManager.totalPages - self.threadViewManager.threads.lastObject.pageNumber)]
                                                                         delegate:self
                                                                cancelButtonTitle:@"取消"
                                                                otherButtonTitles:@"确定", nil];
        [self.confirmMassiveDownloadAlertView show];
    }
}

- (IBAction)replyAction:(id)sender {
    [czzReplyUtil replyMainThread:self.threadViewManager.parentThread];
}

- (IBAction)starAction:(id)sender {
    if (self.threadViewManager.parentThread) {
        if ([favouriteManager isThreadFavourited:self.threadViewManager.parentThread]) {
            // Already contained, remove instead.
            [favouriteManager removeFavourite:self.threadViewManager.parentThread];
            [AppDelegate showToast:@"已移除收藏"];
        } else {
            [favouriteManager addFavourite:self.threadViewManager.parentThread];
            [AppDelegate showToast:@"已加入收藏"];
        }
        [self updateTableView];
    }
}



- (IBAction)jumpAction:(id)sender {
    [self PromptForJumpToPage];
}


- (IBAction)shareAction:(id)sender {
    // Create the thread link - at the moment I am hardcoding it.
    czzThread *sharingThread = self.threadViewManager.parentThread;
    if (sharingThread) {
        NSString *sharingContent = sharingThread.content.string;
        // If the sharing content is longer than 40 characters, chuncate it.
        NSString *contentSummary = sharingContent.length > 100 ? [NSString stringWithFormat:@"%@...", [sharingContent substringToIndex:95]] : sharingContent;
        NSString *threadLink = [[settingCentre share_post_url] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long)sharingThread.ID]];
        // If not nil, put a breakpoint at the end.
        if (contentSummary.length) {
            contentSummary = [contentSummary stringByAppendingString:@"\n"];
            contentSummary = [contentSummary stringByAppendingString:threadLink];
        } else {
            contentSummary = @"";
        }
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[contentSummary]
                                                                                             applicationActivities:nil];
        if ([activityViewController respondsToSelector:@selector(popoverPresentationController)])
            activityViewController.popoverPresentationController.sourceView = self.view;
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (IBAction)togglePOOnlyModeAction:(id)sender {
    [self updateTableView];
}

#pragma mark - Size change.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.threadTableViewManager viewWillTransitionToSize];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - czzMiniThreadViewControllerDelegate

- (void)miniThreadViewController:(czzMiniThreadViewController *)viewController didSelectedQuotedThread:(NSString *)threadID {
    [self.threadTableViewManager userTapInQuotedText:threadID];
}
@end
