    //
//  czzThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadViewController.h"
#import "czzThread.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzImageCacheManager.h"
#import "czzImageViewerUtil.h"
#import "czzAppDelegate.h"
#import "czzHomeViewController.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadRefButton.h"
#import "PartialTransparentView.h"
#import "czzSearchViewController.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzMiniThreadViewController.h"
#import "czzNavigationController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "GSIndeterminateProgressView.h"
#import "czzThreadTableViewManager.h"
#import "czzFavouriteManager.h"
#import "czzWatchListManager.h"
#import "czzRoundButton.h"
#import "czzReplyUtil.h"

NSString * const showThreadViewSegueIdentifier = @"showThreadView";

@interface czzThreadViewController ()<UIAlertViewDelegate>
@property (strong, nonatomic) NSIndexPath *selectedIndex;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
@property (assign, nonatomic) BOOL shouldHighlight;
@property (assign, nonatomic) BOOL shouldDisplayQuickScrollCommand;
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *keywordToSearch;
@property (strong, nonatomic) UIViewController *rightViewController;
@property (strong, nonatomic) UIViewController *topViewController;
@property (strong, nonatomic) czzMiniThreadViewController *miniThreadView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) czzThreadTableViewManager *threadTableViewManager;
@property (strong, nonatomic) czzOnScreenImageManagerViewController *onScreenImageManagerViewController;
@property (weak, nonatomic) GSIndeterminateProgressView *progressView;
@end

@implementation czzThreadViewController
@synthesize numberBarButton;
@synthesize selectedIndex;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldHighlight;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize keywordToSearch;
@synthesize rightViewController;
@synthesize topViewController;
@synthesize miniThreadView;
@synthesize imageViewerUtil;
@synthesize refreshControl;
@synthesize onScreenImageManagerViewContainer;
@synthesize progressView;
@synthesize moreButton;
@synthesize shouldRestoreContentOffset;

#pragma mark - view controller life cycle.
- (void)viewDidLoad
{
    [super viewDidLoad];
    // self.threadViewManager must not be nil.
    assert(self.threadTableViewManager != nil);
    self.threadViewManager.delegate = self;
    [self.threadViewManager restorePreviousState];
    // The manager for the table view.
    self.threadTableView.dataSource = self.threadTableViewManager;
    self.threadTableView.delegate = self.threadTableViewManager;

    // Progress view
    progressView = [(czzNavigationController*)self.navigationController progressView];
    
    // Thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    imageViewerUtil = [czzImageViewerUtil new];
    // Settings
    shouldHighlight = [settingCentre userDefShouldHighlightPO];
    // On screen image manager view controller
    if (!self.onScreenImageManagerViewController) {
        self.onScreenImageManagerViewController = [czzOnScreenImageManagerViewController new];
        self.onScreenImageManagerViewController.delegate = self.threadTableViewManager;
        [self addChildViewController:self.onScreenImageManagerViewController];
        [self.onScreenImageManagerViewContainer addSubview:self.onScreenImageManagerViewController.view];
    }

    //add the UIRefreshControl to uitableview
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [self.threadTableView addSubview: refreshControl];
    self.viewDeckController.rightSize = self.view.frame.size.width/4;

    self.navigationItem.backBarButtonItem.title = self.title;
    
    //if in foreground, load more threads
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        if (self.threadViewManager.restoredFromCache) {
            // Start loading at the end of push animation.
            __weak czzThreadViewController *weakSelf = self;
            NavigationManager.pushAnimationCompletionHandler = ^{
                if (!weakSelf.threadViewManager.threads.count) {
                    [weakSelf refreshThread:weakSelf];
                } else {
                    [weakSelf.threadViewManager loadMoreThreads];
                }
            };
        } else {
            [self refreshThread:self];
        }
    } else {
        DDLogDebug(@"App in background, nothing needs to be done.");
    }
    
    // Google Analytic integration.
    NSString *label = self.threadViewManager.parentThread.content.string;
    // Chunk the text.
    if (label.length > 20) {
        label = [label substringToIndex:19];
    }
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Thread"
                                                                                        action:@"View Thread"
                                                                                         label:label
                                                                                         value:@(self.threadViewManager.parentThread.ID)] build]];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    // Reload data.
    [self updateTableView];
    // Background colour.
    self.threadTableView.backgroundColor = [settingCentre viewBackgroundColour];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Disable right view controller
    self.viewDeckController.rightController = nil;
    // Cache downloaded data into disk.
    [self.threadViewManager saveCurrentState];
}

- (void)dealloc {
    // Avoid calling deacllocated data source and delegate.
    self.threadTableView.dataSource = nil;
    self.threadTableView.delegate = nil;
}


/*
 This method would update the contents related to the table view
 */
-(void)updateTableView {
    // Update bar buttons.
    if (!numberBarButton.customView) {
        numberBarButton.customView = [[czzRoundButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    }
    
    [(czzRoundButton *)numberBarButton.customView setTitle:[NSString stringWithFormat:@"%ld", (long) self.threadViewManager.threads.count] forState:UIControlStateNormal];
    
    // Star button image - on or off.
    if ([favouriteManager isThreadFavourited:self.threadViewManager.parentThread]) {
        self.starButton.image = [UIImage imageNamed:@"solid_star.png"];
    } else {
        self.starButton.image = [UIImage imageNamed:@"star.png"];
    }
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
    self.title = self.threadViewManager.parentThread.title;

    // Update bar buttons.
    if (!numberBarButton.customView) {
        numberBarButton.customView = [[czzRoundButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    }
    
    [(czzRoundButton*)numberBarButton.customView setTitle:[NSString stringWithFormat:@"%ld", (long) self.threadViewManager.threads.count] forState:UIControlStateNormal];
    if (self.threadViewManager.threads.count <= 0)
        numberBarButton.customView.hidden = YES;
    else
        numberBarButton.customView.hidden = NO;
}

-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:self];
}

#pragma mark - jump to and download controls
-(void)PromptForJumpToPage{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %ld/%ld", (long) self.threadViewManager.pageNumber, (long) self.threadViewManager.totalPages] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textInputField = [alertView textFieldAtIndex:0];
    if (textInputField)
    {
        textInputField.keyboardType = UIKeyboardTypeNumberPad;
        textInputField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    [alertView show];
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"确定"]){
        NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
        if (newPageNumber > 0){
            //clear threads and ready to accept new threads
            [self.threadViewManager removeAll];
            [self.threadViewManager loadMoreThreads:newPageNumber];
            [self updateTableView];
            [refreshControl beginRefreshing];

            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long) self.threadViewManager.pageNumber]];
        } else {
            [[AppDelegate window] makeToast:@"页码无效..."];
        }
    }
}

-(void)refreshThread:(id)sender{
    [self.threadViewManager refresh];
    [self updateTableView];
}

#pragma mark - czzThreadViewManagerDelegate
- (void)threadViewManager:(czzThreadViewManager *)threadViewManager wantsToShowContentForThread:(czzThread *)thread {
    self.miniThreadView = [czzMiniThreadViewController new];
    self.miniThreadView.myThread = thread;
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

-(void)homeViewManagerBeginsDownloading:(czzHomeViewManager *)threadViewManager {
    if (!progressView.isAnimating) {
        [progressView startAnimating];
    }
}

-(void)homeViewManager:(czzHomeViewManager *)threadViewManager downloadSuccessful:(BOOL)wasSuccessful {
    if (!wasSuccessful)
    {
        if (progressView.isAnimating) {
            [refreshControl endRefreshing];
            [progressView stopAnimating];
            [progressView showWarning];
        }
    }
}

-(void)homeViewManager:(czzHomeViewManager *)threadViewManager threadContentProcessed:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    if (wasSuccessul) {
        if (newThreads.count) {
            self.threadViewManager = (czzThreadViewManager*)threadViewManager;
        }
    }
    [self updateTableView];
    [refreshControl endRefreshing];
    [progressView stopAnimating];
    // Reset the lastCellType back to default.
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
}

#pragma mark - UI button actions

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

- (IBAction)watchAction:(id)sender {
    [[czzWatchListManager sharedManager] addToWatchList:self.threadViewManager.parentThread];
}


- (IBAction)jumpAction:(id)sender {
    [self PromptForJumpToPage];
}

- (IBAction)reportAction:(id)sender {
    [czzReplyUtil reportThread:self.threadViewManager.parentThread inParentThread:self.threadViewManager.parentThread];
}

- (IBAction)shareAction:(id)sender {
    //create the thread link - hardcode it
    NSString *threadLink = [[settingCentre share_post_url] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long) self.threadViewManager.parentThread.ID]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:threadLink]] applicationActivities:nil];
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)])
        activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go_search_view_segue"]) {
        czzSearchViewController *searchViewController = (czzSearchViewController*)segue.destinationViewController;
        if (keywordToSearch.length > 0)
            searchViewController.predefinedSearchKeyword = keywordToSearch;
    }
}

#pragma mark - Rotation event.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateTableView];
}

#pragma mark - State perserving
- (NSString*)saveCurrentState {
    self.threadViewManager.currentOffSet = self.threadTableView.contentOffset;
    return [self.threadViewManager saveCurrentState];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
}
@end
