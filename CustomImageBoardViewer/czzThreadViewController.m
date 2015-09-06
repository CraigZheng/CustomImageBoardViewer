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
#import "czzImageCentre.h"
#import "czzImageViewerUtil.h"
#import "czzAppDelegate.h"
#import "czzRightSideViewController.h"
#import "czzHomeViewController.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadRefButton.h"
#import "PartialTransparentView.h"
#import "czzSearchViewController.h"
#import "czzSettingsCentre.h"
#import "czzThreadTableViewDataSource.h"
#import "czzTextViewHeightCalculator.h"
#import "czzMiniThreadViewController.h"
#import "czzNavigationController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "GSIndeterminateProgressView.h"
#import "czzThreadViewDelegate.h"

#define OVERLAY_VIEW 122

NSString * const showThreadViewSegueIdentifier = @"showThreadView";

@interface czzThreadViewController ()<UIAlertViewDelegate>
@property (strong, nonatomic) NSIndexPath *selectedIndex;
@property (strong, nonatomic) czzRightSideViewController *threadMenuViewController;
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
@property (strong, nonatomic) czzThreadTableViewDataSource *tableViewDataSource;
@property (strong, nonatomic) czzThreadViewDelegate *threadViewDelegate;

@property GSIndeterminateProgressView *progressView;
@end

@implementation czzThreadViewController
@synthesize numberBarButton;
@synthesize threadTableView;
@synthesize selectedIndex;
@synthesize threadMenuViewController;
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
@synthesize tableViewDataSource;
@synthesize threadViewDelegate;
@synthesize shouldRestoreContentOffset;

#pragma mark - view controller life cycle.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewModelManager.delegate = self;
    [self.viewModelManager restorePreviousState];
    
    threadTableView.dataSource = tableViewDataSource = [czzThreadTableViewDataSource initWithViewModelManager:self.viewModelManager];
    threadTableView.delegate = threadViewDelegate = [czzThreadViewDelegate initWithViewModelManager:self.viewModelManager];
    tableViewDataSource.tableViewDelegate = threadViewDelegate;
    
    //progress view
    progressView = [(czzNavigationController*)self.navigationController progressView];
    
    //thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    imageViewerUtil = [czzImageViewerUtil new];
    //settings

    shouldHighlight = [settingCentre userDefShouldHighlightPO];
    //add the UIRefreshControl to uitableview
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [threadTableView addSubview: refreshControl];
    self.viewDeckController.rightSize = self.view.frame.size.width/4;

    self.navigationItem.backBarButtonItem.title = self.title;
    
    //if in foreground, load more threads
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        if (self.viewModelManager.restoredFromCache) {
            // Start loading at the end of push animation.
            __weak czzThreadViewController *weakSelf = self;
            NavigationManager.pushAnimationCompletionHandler = ^{
                if (!weakSelf.viewModelManager.threads.count) {
                    [weakSelf refreshThread:weakSelf];
                } else {
                    [weakSelf.viewModelManager loadMoreThreads];
                }
            };
        } else {
            [self refreshThread:self];
        }
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"right_menu_view_controller"];
    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.threadViewModelManager = self.viewModelManager;
    self.viewDeckController.rightController = rightController;
    //do not allow panning
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
    //disable left controller
    self.viewDeckController.leftController = nil;

    //background colour
    self.threadTableView.backgroundColor = [settingCentre viewBackgroundColour];
    
    //on screen image manager view
    czzOnScreenImageManagerViewController *onScreenImgMrg = [(czzNavigationController*)self.navigationController onScreenImageManagerView];
    onScreenImgMrg.delegate = threadViewDelegate;
    [self addChildViewController:onScreenImgMrg];
    [onScreenImageManagerViewContainer addSubview:onScreenImgMrg.view];
    
    //if big image mode, perform a reload
    if ([settingCentre userDefShouldUseBigImage])
    {
        [threadTableView reloadData];
    }

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Disable right view controller
    self.viewDeckController.rightController = nil;
    // Cache downloaded data into disk.
    [self.viewModelManager saveCurrentState];
}

- (void)dealloc {
    // Avoid calling deacllocated data source and delegate.
    threadTableView.dataSource = nil;
    threadTableView.delegate = nil;
}

#pragma mark - setter
-(void)setViewModelManager:(czzThreadViewModelManager *)modelManager {
    _viewModelManager = modelManager;
    self.title = self.viewModelManager.parentThread.title;
    [self updateBarButtons];
}

-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:self];
}

#pragma mark - jump to and download controls
-(void)PromptForJumpToPage{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %ld/%ld", (long) self.viewModelManager.pageNumber, (long) self.viewModelManager.totalPages] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
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
            [self.viewModelManager removeAll];
            [self.viewModelManager loadMoreThreads:newPageNumber];
            [threadTableView reloadData];
            [refreshControl beginRefreshing];

            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long) self.viewModelManager.pageNumber]];
        } else {
            [[AppDelegate window] makeToast:@"页码无效..."];
        }
    }
}

-(void)refreshThread:(id)sender{
    [self.viewModelManager refresh];
    [self.threadTableView reloadData];
}

#pragma mark - czzThreadViewModelManagerDelegate
- (void)viewModelManager:(czzThreadViewModelManager *)viewModelManager wantsToShowContentForThread:(czzThread *)thread {
    self.miniThreadView = [czzMiniThreadViewController new];
    self.miniThreadView.myThread = thread;
    [self.miniThreadView show];
}

- (void)viewModelManager:(czzHomeViewModelManager *)viewModelManager wantsToScrollToContentOffset:(CGPoint)offset {
    // If not CGPointZero
    if (!CGPointEqualToPoint(CGPointZero, offset) && self.threadTableView) {
        self.threadTableView.contentOffset = offset;
    }
}

- (void)viewModelManagerWantsToReload:(czzHomeViewModelManager *)manager {
    if (manager.threads.count) {
        [self.threadTableView reloadData];
    }
}

-(void)viewModelManagerBeginDownloading:(czzHomeViewModelManager *)threadList {
    if (!progressView.isAnimating) {
        [progressView startAnimating];
    }
}

-(void)viewModelManager:(czzHomeViewModelManager *)threadList downloadSuccessful:(BOOL)wasSuccessful {
    if (!wasSuccessful)
    {
        if (progressView.isAnimating) {
            [refreshControl endRefreshing];
            [progressView stopAnimating];
            [progressView showWarning];
        }
    }
}

-(void)viewModelManager:(czzHomeViewModelManager *)threadViewModelManager processedSubThreadData:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    if (wasSuccessul) {
        if (newThreads.count) {
            self.viewModelManager = (czzThreadViewModelManager*)threadViewModelManager;
        }
    }
    [threadTableView reloadData];
    [refreshControl endRefreshing];
    [progressView stopAnimating];
    // Reset the lastCellType back to default.
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
}

-(void)updateBarButtons {
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

    [numberButton setTitle:[NSString stringWithFormat:@"%ld", (long) self.viewModelManager.threads.count] forState:UIControlStateNormal];
    if (self.viewModelManager.threads.count <= 0)
        numberButton.hidden = YES;
    else
        numberButton.hidden = NO;
    self.navigationItem.rightBarButtonItems = @[moreButton, numberBarButton];
    
    // Jump button
    NSString *pageNumber = [NSString stringWithFormat:@"%ld", (long)self.viewModelManager.pageNumber];
    NSString *totalPages = self.viewModelManager.totalPages < 99 ? [NSString stringWithFormat:@"%ld", (long)self.viewModelManager.totalPages] : @"∞";
    self.jumpBarButtonItem.image = nil;
    self.jumpBarButtonItem.title = [NSString stringWithFormat:@"%@/%@", pageNumber, totalPages];
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
    NSString *threadLink = [[settingCentre share_post_url] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long) self.viewModelManager.parentThread.ID]];
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

#pragma mark - rotation change

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

#pragma mark - State perserving
- (NSString*)saveCurrentState {
    self.viewModelManager.currentOffSet = self.threadTableView.contentOffset;
    return [self.viewModelManager saveCurrentState];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
}
@end
