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
#import "czzOnScreenCommandViewController.h"
#import "czzSearchViewController.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzMiniThreadViewController.h"
#import "czzNavigationController.h"
#import "czzOnScreenImageManagerViewController.h"
#import "czzSubThreadList.h"
#import "GSIndeterminateProgressView.h"

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
@property czzOnScreenCommandViewController *onScreenCommandViewController;
@property BOOL shouldDisplayQuickScrollCommand;
@property NSString *thumbnailFolder;
@property NSString *keywordToSearch;
@property czzSettingsCentre *settingsCentre;
@property UIViewController *rightViewController;
@property UIViewController *topViewController;
@property czzMiniThreadViewController *miniThreadView;
@property BOOL viewControllerNotInTransition;
@property UIRefreshControl *refreshControl;
@property czzSubThreadList *threadList;
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
@synthesize parentThread;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldHighlight;
@synthesize shouldHighlightSelectedUser;
@synthesize verticalHeights;
@synthesize horizontalHeights;
@synthesize onScreenCommandViewController;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize keywordToSearch;
@synthesize settingsCentre;
@synthesize rightViewController;
@synthesize topViewController;
@synthesize viewControllerNotInTransition;
@synthesize miniThreadView;
@synthesize imageViewerUtil;
@synthesize refreshControl;
@synthesize onScreenImageManagerViewContainer;
@synthesize threadList;
@synthesize progressView;
@synthesize moreButton;
@synthesize shouldRestoreContentOffset;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //init arrays
    threads = [NSMutableArray new];
    verticalHeights = [NSMutableArray new];
    horizontalHeights = [NSMutableArray new];

    //thread list, source of all data
    threadList = [[czzSubThreadList alloc] initWithParentThread:parentThread];
    [threadList restorePreviousState];
    threadList.delegate = self;
    threadList.parentViewController = self;
    [self copyDataFromThreadList];

    //progress view
    progressView = [(czzNavigationController*)self.navigationController progressView];
    
    //thumbnail folder
    thumbnailFolder = [czzAppDelegate thumbnailFolder];
    imageViewerUtil = [czzImageViewerUtil new];
    //settings
    settingsCentre = [czzSettingsCentre sharedInstance];
    shouldHighlight = settingsCentre.userDefShouldHighlightPO;
    //add the UIRefreshControl to uitableview
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    [threadTableView addSubview: refreshControl];
    self.viewDeckController.rightSize = self.view.frame.size.width/4;

    //register xib
    [self.threadTableView registerNib:[UINib nibWithNibName:THREAD_TABLE_VLEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:THREAD_VIEW_CELL_IDENTIFIER];
    [self.threadTableView registerNib:[UINib nibWithNibName:BIG_IMAGE_THREAD_TABLE_VIEW_CELL_NIB_NAME bundle:nil] forCellReuseIdentifier:BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER];
    self.title = parentThread.title;
    self.navigationItem.backBarButtonItem.title = self.title;
    
    //set up custom edit menu
    UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:@selector(menuActionReply:)];
    UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(menuActionCopy:)];
    UIMenuItem *openMenuItem = [[UIMenuItem alloc] initWithTitle:@"打开链接" action:@selector(menuActionOpen:)];
    UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"高亮他" action:@selector(menuActionHighlight:)];
    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, searchMenuItem, openMenuItem]];
    [[UIMenuController sharedMenuController] update];
    //show on screen command
    onScreenCommandViewController = [[UIStoryboard storyboardWithName:@"OnScreenCommand" bundle:nil] instantiateInitialViewController];
    [self addChildViewController:onScreenCommandViewController];
    [onScreenCommandViewController hide];
    shouldDisplayQuickScrollCommand = settingsCentre.userDefShouldShowOnScreenCommand;
    
    //if in foreground, load more threads
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        [threadList loadMoreThreads];
    }

    //register an obverser while adding a parent view controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(entersBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"right_menu_view_controller"];    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.parentThread = parentThread;
    threadMenuViewController.selectedThread = parentThread;
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
    self.threadTableView.backgroundColor = settingsCentre.viewBackgroundColour;
    
    //on screen image manager view
    czzOnScreenImageManagerViewController *onScreenImgMrg = [(czzNavigationController*)self.navigationController onScreenImageManagerView];
    onScreenImgMrg.view.frame = onScreenImageManagerViewContainer.bounds;
    onScreenImgMrg.delegate = self;
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
    //hide on screen command
    [onScreenCommandViewController hide];
    //no longer ready for more push animation
    viewControllerNotInTransition = NO;
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [threadList saveCurrentState];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //ready for push animation
    viewControllerNotInTransition = YES;
}

-(void)entersBackground {
    if (threadList)
        [threadList saveCurrentState];
}

-(void)copyDataFromThreadList {
    if (shouldRestoreContentOffset && CGPointEqualToPoint(threadTableView.contentOffset, CGPointZero)) {
        [threadTableView setContentOffset:threadList.currentOffSet animated:NO];
    }
    if (threadList.threads.count > 0)
        threads = [NSArray arrayWithArray:threadList.threads];
    if (threadList.horizontalHeights.count > 0)
        horizontalHeights = [NSArray arrayWithArray:threadList.horizontalHeights];
    if (threadList.verticalHeights.count > 0)
        verticalHeights = [NSArray arrayWithArray:threadList.verticalHeights];
    [self updateNumberButton];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (threads.count > 0)
        return threads.count + 1;
    return threads.count;
}

#pragma mark UITableView delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cell_identifier = [[czzSettingsCentre sharedInstance] userDefShouldUseBigImage] ? BIG_IMAGE_THREAD_VIEW_CELL_IDENTIFIER : THREAD_VIEW_CELL_IDENTIFIER;
    if (indexPath.row == threads.count){
        UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (threadList.isDownloading || threadList.isProcessing) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        } else if (parentThread.responseCount > settingsCentre.response_per_page && (threadList.pageNumber * settingsCentre.response_per_page + threads.count % settingsCentre.response_per_page - 1) < parentThread.responseCount){

            cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"no_more_cell_identifier"];
        }
        cell.backgroundColor = [settingsCentre viewBackgroundColour];
        return cell;
    }
    czzThread *thread = [threads objectAtIndex:indexPath.row];

    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier forIndexPath:indexPath];
    // Configure the cell...
    if (cell){
        cell.delegate = self;
        cell.shouldHighlightSelectedUser = shouldHighlightSelectedUser;
        cell.parentThread = parentThread;
        cell.myThread = thread;
        cell.myIndexPath = indexPath;
    }
    return cell;
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        czzThread *selectedThread = [threads objectAtIndex:indexPath.row];
        if (selectedThread){
            [threadMenuViewController setSelectedThread:selectedThread];
        }
    } else {
        [threadList loadMoreThreads];
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %ld/%ld", (long) threadList.pageNumber, (long) threadList.totalPages] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textInputField = [alertView textFieldAtIndex:0];
    if (textInputField)
    {
        textInputField.keyboardType = UIKeyboardTypeNumberPad;
        textInputField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    [alertView show];
}

#pragma mark - scrollToTop and scrollToBottom 
-(void)scrollTableViewToTop {
    [threadTableView setContentOffset:CGPointMake(0.0f, -threadTableView.contentInset.top) animated:YES];
}

-(void)scrollTableViewToBottom {
    @try {
        if (threads.count > 1)
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:threads.count inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    @catch (NSException *exception) {
        
    }
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
            [threadList removeAll];
            [threadList loadMoreThreads:newPageNumber];
            [threadTableView reloadData];
            [refreshControl beginRefreshing];

            [[[czzAppDelegate sharedAppDelegate] window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long) threadList.pageNumber]];
        } else {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"页码无效..."];
        }
    }
}

-(void)refreshThread:(id)sender{
    [threadList refresh];
}


#pragma mark - czzMiniThreadViewProtocol
-(void)miniThreadViewFinishedLoading:(BOOL)successful {
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (!successful) {
        [[czzAppDelegate sharedAppDelegate].window makeToast:[NSString stringWithFormat:@"无法下载:%ld", (long)miniThreadView.threadID]];
        
    } else if (viewControllerNotInTransition)
        [self presentViewController:miniThreadView animated:YES completion:nil];
}

-(void)miniThreadWantsToOpenThread:(czzThread*)thread {
    [self dismissViewControllerAnimated:YES completion:^{
        [self switchToParentThread:thread];
    }];
}


#pragma mark - UIScrollVIew delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (onScreenCommandViewController && threads.count > 1 && shouldDisplayQuickScrollCommand) {
        [onScreenCommandViewController show];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    threadList.currentOffSet = scrollView.contentOffset;
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
            if (threadList.pageNumber < threadList.totalPages) {
                [threadList loadMoreThreads];
                [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

#pragma mark - czzSubThreadListProtocol
-(void)threadListBeginDownloading:(czzThreadList *)threadList {
//    DLog(@"%@", NSStringFromSelector(_cmd));
    if (!progressView.isAnimating) {
        [progressView startAnimating];
    }
}

-(void)threadListDownloaded:(czzThreadList *)threadList wasSuccessful:(BOOL)wasSuccessful {
    if (!wasSuccessful)
    {
        if (progressView.isAnimating) {
            [refreshControl endRefreshing];
            [progressView stopAnimating];
            [progressView showWarning];
        }
    }
}

-(void)subThreadProcessed:(czzThreadList *)threadList wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    if (wasSuccessul) {
        [self copyDataFromThreadList];
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
    NSString *threadLink = [[settingCentre share_post_url] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:threadLink]] applicationActivities:nil];
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)])
        activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - TableViewCellDelegate
-(void)userTapInImageView:(NSString *)imgURL {
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:imgURL.lastPathComponent.lowercaseString])
        {
            [self openImageWithPath:file];
            return;
        }
    }
}

-(void)userTapInQuotedText:(NSString *)text {
    NSInteger refNumber = text.integerValue;
    
    for (czzThread *thread in threads) {
        if (thread.ID == refNumber){
            //record the current content offset
            threadsTableViewContentOffSet = threadTableView.contentOffset;
            //scroll to the tapped cell
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
            //retrive the tapped tableview cell from the tableview
            UITableViewCell *selectedCell = [threadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0]];
            [self highlightTableViewCell:selectedCell];
            return;
        }
    }
    
    //not in this thread
    [[czzAppDelegate sharedAppDelegate].window makeToast:[NSString stringWithFormat:@"需要下载: %@", text]];
    miniThreadView = [[UIStoryboard storyboardWithName:@"MiniThreadView" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    miniThreadView.delegate = self;
    [miniThreadView setThreadID:refNumber];
}

-(void)imageDownloadedForIndexPath:(NSIndexPath *)index filePath:(NSString *)path isThumbnail:(BOOL)isThumbnail {
    if (isThumbnail)
    {
        if (index && index.row < threads.count) {
            @try {
                [threadTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            @catch (NSException *exception) {
                DLog(@"%@", exception);
            }
        }
    } else if (settingsCentre.userDefShouldAutoOpenImage) {
        [self openImageWithPath:path];
    }
}

#pragma mark - high light
-(void)highlightTableViewCell:(UITableViewCell*)tableviewcell{
    //disable the scrolling view
    self.threadTableView.scrollEnabled = NO;
    PartialTransparentView *containerView = [[PartialTransparentView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.threadTableView.contentSize.height) backgroundColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.7f] andTransparentRects:[NSArray arrayWithObject:[NSValue valueWithCGRect:tableviewcell.frame]]];
    
    containerView.userInteractionEnabled = YES;
    containerView.tag = OVERLAY_VIEW;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    containerView.alpha = 0.0f;
    [threadTableView addSubview:containerView];
    [UIView animateWithDuration:0.2
                     animations:^{containerView.alpha = 1.0f;}
                     completion:^(BOOL finished){[containerView addGestureRecognizer:tapRecognizer];}];
    
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
            self.parentThread = newParentThread;
            [threadList setParentThread:self.parentThread];
            [self refreshThread:nil];
        });
    }
}

#pragma mark - rotation change
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    UIView *containerView = [[[czzAppDelegate sharedAppDelegate] window] viewWithTag:OVERLAY_VIEW];
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


@end
