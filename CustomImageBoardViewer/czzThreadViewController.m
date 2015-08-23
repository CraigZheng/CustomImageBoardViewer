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

@interface czzThreadViewController ()<czzThreadListProtocol, UIAlertViewDelegate, czzMenuEnabledTableViewCellProtocol, czzMiniThreadViewControllerProtocol, czzOnScreenImageManagerViewControllerDelegate>
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSArray *threads;
@property NSArray *verticalHeights;
@property NSArray *horizontalHeights;
@property NSIndexPath *selectedIndex;
@property czzRightSideViewController *threadMenuViewController;
@property czzImageViewerUtil *imageViewerUtil;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
@property BOOL shouldHighlight;
@property BOOL shouldDisplayQuickScrollCommand;
@property NSString *thumbnailFolder;
@property NSString *keywordToSearch;
@property UIViewController *rightViewController;
@property UIViewController *topViewController;
@property czzMiniThreadViewController *miniThreadView;
@property BOOL viewControllerNotInTransition;
@property UIRefreshControl *refreshControl;
@property czzThreadTableViewDataSource *tableViewDataSource;
@property czzThreadViewDelegate *threadViewDelegate;

@property GSIndeterminateProgressView *progressView;
@end

@implementation czzThreadViewController
@synthesize baseURLString;
@synthesize numberBarButton;
@synthesize targetURLString;
@synthesize threads;
@synthesize threadTableView;
@synthesize selectedIndex;
@synthesize threadMenuViewController;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldHighlight;
@synthesize shouldHighlightSelectedUser;
@synthesize verticalHeights;
@synthesize horizontalHeights;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize keywordToSearch;
@synthesize rightViewController;
@synthesize topViewController;
@synthesize viewControllerNotInTransition;
@synthesize miniThreadView;
@synthesize imageViewerUtil;
@synthesize refreshControl;
@synthesize onScreenImageManagerViewContainer;
@synthesize threadViewModelManager;
@synthesize progressView;
@synthesize moreButton;
@synthesize tableViewDataSource;
@synthesize threadViewDelegate;
@synthesize shouldRestoreContentOffset;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    threadViewModelManager.delegate = self;
    [self applyViewModel];
    
    threadTableView.dataSource = tableViewDataSource = [czzThreadTableViewDataSource initWithViewModelManager:self.threadViewModelManager];
    threadTableView.delegate = threadViewDelegate = [czzThreadViewDelegate initWithViewModelManager:threadViewModelManager];
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

    self.title = threadViewModelManager.parentThread.title;
    self.navigationItem.backBarButtonItem.title = self.title;
    
    //if in foreground, load more threads
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        if (threadViewModelManager.pageNumber == 1) {
            [threadViewModelManager refresh];
        } else {
            [threadViewModelManager loadMoreThreads];
        }
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"right_menu_view_controller"];    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.parentThread = threadViewModelManager.parentThread;
    threadMenuViewController.forum = threadViewModelManager.forum;
    threadMenuViewController.selectedThread = threadViewModelManager.parentThread;
    self.viewDeckController.rightController = rightController;
    //do not allow panning
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
    //disable left controller
    self.viewDeckController.leftController = nil;
    //Jump to command observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PromptForJumpToPage) name:@"JumpToPageCommand" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HighlightThreadSelected:) name:@"HighlightAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SearchUser:) name:@"SearchAction" object:nil];

    //background colour
    self.threadTableView.backgroundColor = [settingCentre viewBackgroundColour];
    
    //on screen image manager view
    czzOnScreenImageManagerViewController *onScreenImgMrg = [(czzNavigationController*)self.navigationController onScreenImageManagerView];
    onScreenImgMrg.view.frame = onScreenImageManagerViewContainer.bounds;
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
    //disable right view controller
    self.viewDeckController.rightController = nil;
    //no longer ready for more push animation
    viewControllerNotInTransition = NO;
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
#warning DEBUGGING ONLY
    [self.threadViewModelManager saveCurrentState];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //ready for push animation
    viewControllerNotInTransition = YES;
}

-(void)applyViewModel {
    if (shouldRestoreContentOffset && CGPointEqualToPoint(threadTableView.contentOffset, CGPointZero)) {
        [threadTableView setContentOffset:threadViewModelManager.currentOffSet animated:NO];
    }
    if (threadViewModelManager.threads.count > 0)
        threads = [NSArray arrayWithArray:threadViewModelManager.threads];
    if (threadViewModelManager.horizontalHeights.count > 0)
        horizontalHeights = [NSArray arrayWithArray:threadViewModelManager.horizontalHeights];
    if (threadViewModelManager.verticalHeights.count > 0)
        verticalHeights = [NSArray arrayWithArray:threadViewModelManager.verticalHeights];
    [self updateNumberButton];
}

#pragma mark UITableView delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        czzThread *selectedThread = [threads objectAtIndex:indexPath.row];
        if (selectedThread){
            [threadMenuViewController setSelectedThread:selectedThread];
        }
    } else {
        [threadViewModelManager loadMoreThreads];
        [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < threads.count)
        return YES;
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
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

-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:self];
}

#pragma mark - jump to and download controls
-(void)PromptForJumpToPage{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %ld/%ld", (long) threadViewModelManager.pageNumber, (long) threadViewModelManager.totalPages] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textInputField = [alertView textFieldAtIndex:0];
    if (textInputField)
    {
        textInputField.keyboardType = UIKeyboardTypeNumberPad;
        textInputField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    [alertView show];
}

#pragma mark - highlight thread selected
-(void)HighlightThreadSelected:(NSNotification*)notification {
    czzThread *selectedThread = [notification.userInfo objectForKey:@"HighlightThread"];
    if (selectedThread) {
        if ([shouldHighlightSelectedUser isEqual:selectedThread.UID.string]) {
            shouldHighlightSelectedUser = nil;
        }
        else
            shouldHighlightSelectedUser = selectedThread.UID.string;
        self.tableViewDataSource.shouldHighlightSelectedUser = shouldHighlightSelectedUser;
        [threadTableView reloadData];
    }
}

#pragma mark - search this particula user 
-(void)SearchUser:(NSNotification*)notification {
    czzThread *selectedThread = [notification.userInfo objectForKey:@"SearchUser"];
    if (selectedThread) {
        keywordToSearch = selectedThread.UID.string;
        [self performSegueWithIdentifier:@"go_search_view_segue" sender:self];
    }
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"确定"]){
        NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
        if (newPageNumber > 0){
            //clear threads and ready to accept new threads
            [threadViewModelManager removeAll];
            [threadViewModelManager loadMoreThreads:newPageNumber];
            [threadTableView reloadData];
            [refreshControl beginRefreshing];

            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long) threadViewModelManager.pageNumber]];
        } else {
            [[AppDelegate window] makeToast:@"页码无效..."];
        }
    }
}

-(void)refreshThread:(id)sender{
    [threadViewModelManager refresh];
}


#pragma mark - czzMiniThreadViewProtocol
-(void)miniThreadViewFinishedLoading:(BOOL)successful {
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (!successful) {
        [AppDelegate.window makeToast:[NSString stringWithFormat:@"无法下载:%ld", (long)miniThreadView.threadID]];
        
    } else if (viewControllerNotInTransition)
        [self presentViewController:miniThreadView animated:YES completion:nil];
}

-(void)miniThreadWantsToOpenThread:(czzThread*)thread {
    [self dismissViewControllerAnimated:YES completion:^{
//        [self switchToParentThread:thread];
        czzThreadViewController *openThreadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"thread_view_controller"];
        threadViewModelManager.parentThread = thread;
        openThreadViewController.threadViewModelManager = threadViewModelManager;
        [self.navigationController pushViewController:openThreadViewController animated:YES];
    }];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    NSArray *visibleRows = [threadTableView visibleCells];
    UITableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *path = [threadTableView indexPathForCell:lastVisibleCell];
    if(path.row == threads.count && threads.count > 0)
    {
        CGRect lastCellRect = [threadTableView rectForRowAtIndexPath:path];
        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.frame.size.height && !(threadViewModelManager.isDownloading || threadViewModelManager.isProcessing)){
            if (threadViewModelManager.pageNumber < threadViewModelManager.totalPages) {
                [threadViewModelManager loadMoreThreads];
                [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

#pragma mark - czzSubthreadViewModelManagerProtocol
-(void)threadViewModelManagerBeginDownloading:(czzHomeViewModelManager *)threadViewModelManager {
    if (!progressView.isAnimating) {
        [progressView startAnimating];
    }
}

-(void)threadViewModelManagerDownloaded:(czzHomeViewModelManager *)threadViewModelManager wasSuccessful:(BOOL)wasSuccessful {
    if (!wasSuccessful)
    {
        if (progressView.isAnimating) {
            [refreshControl endRefreshing];
            [progressView stopAnimating];
            [progressView showWarning];
        }
    }
    // Reset the lastCellType back to default.
    self.threadTableView.lastCellType = czzThreadTableViewLastCommandCellTypeLoadMore;
}

-(void)subThreadProcessed:(czzHomeViewModelManager *)threadViewModelManager wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    if (wasSuccessul) {
        [self applyViewModel];
        [threadTableView reloadData];
        [refreshControl endRefreshing];
        [progressView stopAnimating];
    }
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
    if (threads.count <= 0)
        numberButton.hidden = YES;
    else
        numberButton.hidden = NO;
    self.navigationItem.rightBarButtonItems = @[moreButton, numberBarButton];
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
    NSString *threadLink = [[settingCentre share_post_url] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long) threadViewModelManager.parentThread.ID]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:threadLink]] applicationActivities:nil];
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)])
        activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
}
-(void)tapOnFloatingView:(UIGestureRecognizer*)gestureRecognizer{
    PartialTransparentView *containerView = (PartialTransparentView*)[threadTableView viewWithTag:OVERLAY_VIEW];
    [UIView animateWithDuration:0.2 animations:^{
        containerView.alpha = 0.0f;
    } completion:^(BOOL finished){
        [containerView removeFromSuperview];
        //scroll back to the original position
    }];
    CGPoint touchPoint = [gestureRecognizer locationInView:threadTableView];
    NSArray *rectArray = containerView.rectsArray;
    BOOL userTouchInView = NO;
    for (NSValue *rect in rectArray) {
        if (CGRectContainsPoint([rect CGRectValue], touchPoint)) {
            userTouchInView = YES;
            break;
        }
    }
    
    if (!userTouchInView)
        [threadTableView setContentOffset:threadsTableViewContentOffSet animated:YES];
    threadTableView.scrollEnabled = YES;
}

//show image
-(void)openImageWithPath:(NSString*)path{
    if (viewControllerNotInTransition)
        [imageViewerUtil showPhoto:path inViewController:self];
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

#pragma mark - prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go_search_view_segue"]) {
        czzSearchViewController *searchViewController = (czzSearchViewController*)segue.destinationViewController;
        if (keywordToSearch.length > 0)
            searchViewController.predefinedSearchKeyword = keywordToSearch;
    }
}

#pragma mark - switch parent thread
-(void)switchToParentThread:(czzThread*)newParentThread {
    if (newParentThread)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [threadViewModelManager setParentThread:newParentThread];
            [self refreshThread:nil];
        });
    }
}

#pragma mark - rotation change
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    UIView *containerView = [[AppDelegate window] viewWithTag:OVERLAY_VIEW];
    //if the container view is not nil, deselect it
    if (containerView)
        [self performSelector:@selector(tapOnFloatingView:) withObject:nil];
}

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

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
}
@end
