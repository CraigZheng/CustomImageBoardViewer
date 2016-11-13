    //
//  czzThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadViewController.h"
#import "czzThread.h"
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
#import "czzThreadTableViewManager.h"
#import "czzFavouriteManager.h"
#import "czzWatchListManager.h"
#import "czzRoundButton.h"
#import "czzPostSenderManagerViewController.h"
#import "czzReplyUtil.h"
#import "czzAutoEndingRefreshControl.h"
#import "czzThreadViewManager.h"
#import "UIImage+animatedGIF.h"

#import "CustomImageBoardViewer-Swift.h"

NSString * const showThreadViewSegueIdentifier = @"showThreadView";

@interface czzThreadViewController ()<UIAlertViewDelegate, czzThreadViewManagerDelegate>
@property (strong, nonatomic) NSIndexPath *selectedIndex;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
@property (assign, nonatomic) BOOL shouldDisplayQuickScrollCommand;
@property (strong, nonatomic) NSString *thumbnailFolder;
@property (strong, nonatomic) NSString *keywordToSearch;
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
@property (weak, nonatomic) IBOutlet UIButton *massiveDownloadButton;
@property (strong, nonatomic) czzThreadViewManager *threadViewManager;
@end

@implementation czzThreadViewController
@synthesize numberBarButton;
@synthesize selectedIndex;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize keywordToSearch;
@synthesize rightViewController;
@synthesize topViewController;
@synthesize miniThreadView;
@synthesize imageViewerUtil;
@synthesize onScreenImageManagerViewContainer;
@synthesize moreButton;
@synthesize shouldRestoreContentOffset;

#pragma mark - view controller life cycle.
- (void)viewDidLoad
{
    [super viewDidLoad];
    // If self.thread is not ready, the whole view controller is not ready.
    if (self.thread) {
        [self commonInit];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // UI appearance.
    self.threadTableView.backgroundColor = [settingCentre viewBackgroundColour];
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
    [self.threadViewManager restorePreviousState];
    self.title = self.threadViewManager.parentThread.title;
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
        [self addChildViewController:self.onScreenImageManagerViewController];
        [self.onScreenImageManagerViewContainer addSubview:self.onScreenImageManagerViewController.view];
    }
    // Post sender manager view controller.
    czzPostSenderManagerViewController *postSenderManagerViewController = [czzPostSenderManagerViewController new];
    [self addChildViewController:postSenderManagerViewController];
    [self.postSenderViewContainer addSubview:postSenderManagerViewController.view];
    
    //add the UIRefreshControl to uitableview
    self.refreshControl = [[czzAutoEndingRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [self.threadTableView addSubview: self.refreshControl];
    
    self.navigationItem.backBarButtonItem.title = self.title;
    
    // What to do when this view controller has completed loading.
    __weak czzThreadViewController *weakSelf = self;
    void (^onLoadAction)(void) = ^void(void) {
        // If threads array contains nothing other than the parent thread.
        if (weakSelf.threadViewManager.threads.count <=1 ) {
            [weakSelf refreshThread:weakSelf];
        } else {
            [weakSelf.threadViewManager loadMoreThreads];
        }
    };
    
    if (NavigationManager.isInTransition) {
        NavigationManager.pushAnimationCompletionHandler = ^{
            onLoadAction();
        };
    } else {
        onLoadAction();
    }
    // Google Analytic integration.
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Thread"
                                                                                        action:@"View Thread"
                                                                                         label:[NSString stringWithFormat:@"%ld", (long)self.threadViewManager.parentThread.ID]
                                                                                         value:@1] build]];
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
    // Watch button image - watched or not.
    if ([WatchListManager.watchedThreads containsObject:self.threadViewManager.parentThread]) {
        self.watchButton.image = [UIImage imageNamed:@"visible.png"];
    } else {
        self.watchButton.image = [UIImage imageNamed:@"invisible.png"];
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
    if (viewManager) {
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
        // Hide the massive download button at first, then show it with animation.
        // Show it only when the total pages is still 3 or more pages away from the current page number.
        if (!self.massiveDownloadButtonHeightConstraint.constant &&
            viewManager.totalPages - viewManager.pageNumber >= 3) {
            self.massiveDownloadButtonHeightConstraint.constant = 40;
            [UIView animateWithDuration:0.2 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
        // Else, if the massive download button is showing and view manager has reached all of its pages.
        else if (self.massiveDownloadButtonHeightConstraint.constant &&
                 viewManager.pageNumber >= viewManager.totalPages) {
            self.massiveDownloadButtonHeightConstraint.constant = 0;
            [UIView animateWithDuration:0.2 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }
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
                //clear threads and ready to accept new threads
                [self.threadViewManager removeAll];
                [self.threadViewManager loadMoreThreads:newPageNumber];
                [self updateTableView];
                
                [MessagePopup showMessageWithTitle:nil message:[NSString stringWithFormat:@"跳到第 %ld 页...", (long) newPageNumber]];
            } else {
                [MessagePopup showMessageWithTitle:nil message:@"页码无效..."];
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

- (IBAction)massiveDownloadAction:(id)sender {
    if (self.threadViewManager.isMassiveDownloading) {
        // Stop massive download.
        self.confirmCancelMassiveDownloadAlertView = [[UIAlertView alloc] initWithTitle:@"取消一键到底!"
                                                                                message:[NSString stringWithFormat:@"是否取消一键到底?"]
                                                                               delegate:self
                                                                      cancelButtonTitle:@"算了"
                                                                      otherButtonTitles:@"确定", nil];
        [self.confirmCancelMassiveDownloadAlertView show];
    } else {
        // Start massive download.
        self.confirmMassiveDownloadAlertView = [[UIAlertView alloc] initWithTitle:@"一键到底!"
                                                                          message:[NSString stringWithFormat:@"将加载%ld页内容,请确认!",
                                                                                   self.threadViewManager.totalPages - self.threadViewManager.pageNumber]
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

- (IBAction)watchAction:(id)sender {
    czzThread *targetThread = self.threadViewManager.parentThread;
    if ([WatchListManager.watchedThreads containsObject:targetThread]) {
        [AppDelegate showToast:@"已取消注目"];
        [WatchListManager removeFromWatchList:targetThread];
    } else {
        [AppDelegate showToast:@"已注目此串"];
        [WatchListManager addToWatchList:targetThread];
    }
    [self updateTableView];
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

#pragma mark - State perserving and restoration.

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    DLog(@"");
    // Save the current thread.
    [coder encodeObject:self.thread forKey:@"thread"];
    [coder encodeObject:[NSValue valueWithCGPoint:self.threadTableView.contentOffset] forKey:@"TableViewContentOffset"];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    DLog(@"");
    [super decodeRestorableStateWithCoder:coder];
    // Restore the thread.
    self.thread = [coder decodeObjectForKey:@"thread"];
    NSValue *contentOffsetValue;
    if ([(contentOffsetValue = [coder decodeObjectForKey:@"TableViewContentOffset"]) isKindOfClass:[NSValue class]]) {
        [self.threadTableView setContentOffset:contentOffsetValue.CGPointValue];
    }
}

- (void)applicationFinishedRestoringState {
    DLog(@"");
    if (self.thread) {
        [self commonInit];
    }
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
}
@end
