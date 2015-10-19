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
#import "czzForumsViewController.h"
#import "czzThreadTableView.h"
#import "czzSettingsViewController.h"
#import "czzRoundButton.h"
#import "czzFavouriteManagerViewController.h"

#import "czzHomeTableViewDataSource.h"

#import <CoreText/CoreText.h>


@interface czzHomeViewController() <UIAlertViewDelegate, czzOnScreenImageManagerViewControllerDelegate, UIStateRestoring>
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
    if (!CGPointEqualToPoint(CGPointZero, self.viewModelManager.currentOffSet)) {
        [self.threadTableView setContentOffset:self.viewModelManager.currentOffSet animated:NO];
    }
    // Set the currentOffSet back to zero
    self.viewModelManager.currentOffSet = CGPointZero;

    //configure the view deck controller with half size and tap to close mode
    self.viewDeckController.leftSize = self.view.frame.size.width/4;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;

    //register a notification observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forumPicked:)
                                                 name:kForumPickedNotification
                                               object:nil];
    
    [self.threadTableView addSubview:self.refreshControl];
    // Init the left
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //on screen image manager view
    czzOnScreenImageManagerViewController *onScreenImgMrg = [NavigationManager.delegate onScreenImageManagerView];
    onScreenImgMrg.delegate = self.homeViewDelegate;
    [self addChildViewController:onScreenImgMrg];
    [self.onScreenImageManagerViewContainer addSubview:onScreenImgMrg.view];
    
    self.threadTableView.backgroundColor = settingCentre.viewBackgroundColour;
    
    // Always reload
    [self updateTableView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
    // Check if should show a badget on settings button.
    UIButton *settingsGearImageButton;
    if (!self.settingsBarButton.customView) {
        //create a container view that has an image button as its sub view
        settingsGearImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 37)];
        settingsGearImageButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [settingsGearImageButton setImage:[[UIImage imageNamed:@"settings.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        settingsGearImageButton.tag = 999;
        // Add the container view.
        self.settingsBarButton.customView = settingsGearImageButton;
    } else {
        // Retrive the gear image button.
        settingsGearImageButton = (UIButton*) [self.settingsBarButton.customView viewWithTag:999];
    }
    if ([[(czzNavigationController*)self.navigationController notificationBannerViewController] shouldShow]) {
        self.settingsBarButton.badgeValue = @"1";
        [settingsGearImageButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [settingsGearImageButton addTarget:self action:@selector(openNotificationCentre) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.settingsBarButton.badgeValue = nil;
        [settingsGearImageButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [settingsGearImageButton addTarget:self action:@selector(openSettingsPanel) forControlEvents:UIControlEventTouchUpInside];
    }

    // Select a random forum after a certain period of inactivity.
    NSTimeInterval delayTime = 4.0;
#ifdef DEBUG
    delayTime = 9999;
#endif
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.viewModelManager.forum) {
            if ([czzForumManager sharedManager].forums.count > 0)
            {
                [AppDelegate.window makeToast:@"用户没有选择板块，随机选择……"];
                @try {
                    int randomIndex = rand() % [czzForumManager sharedManager].forums.count;
                    [self.viewModelManager setForum:[[czzForumManager sharedManager].forums objectAtIndex:randomIndex]];
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
    [self.threadTableView reloadData];
    
    // Update bar buttons.
    if (!self.numberBarButton.customView) {
        self.numberBarButton.customView = [[czzRoundButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    }
    
    [(czzRoundButton *)self.numberBarButton.customView setTitle:[NSString stringWithFormat:@"%ld", (long) self.viewModelManager.threads.count] forState:UIControlStateNormal];
    
    // Jump button
    self.jumpBarButtonItem.image = nil;
    self.jumpBarButtonItem.title = [NSString stringWithFormat:@"%ld", (long)self.viewModelManager.pageNumber];
    
    // Other data
    self.title = self.viewModelManager.forum.name;
    self.navigationItem.backBarButtonItem.title = self.title;
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
            [self.viewModelManager removeAll];
            [self updateTableView];
            [self.refreshControl beginRefreshing];
            [self.viewModelManager loadMoreThreads:newPageNumber];

            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"跳到第 %ld 页...", (long)self.viewModelManager.pageNumber]];
        } else {
            [[AppDelegate window] makeToast:@"页码无效..."];
        }
    }
}

#pragma mark - more action and commands
-(void)openSettingsPanel{
    czzSettingsViewController *settingsViewController = [czzSettingsViewController new];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

-(void)openNotificationCentre {
    czzNotificationCentreTableViewController *notificationCentreViewController = [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [self.navigationController pushViewController:notificationCentreViewController animated:YES];
}

-(void)newPost{
    if (self.viewModelManager.forum){
        czzPostViewController *newPostViewController = [czzPostViewController new];
        newPostViewController.forum = self.viewModelManager.forum;
        newPostViewController.postMode = NEW_POST;
        [self.navigationController pushViewController:newPostViewController animated:YES];
    } else {
        [[AppDelegate window] makeToast:@"未选定一个版块" duration:1.0 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
}

-(IBAction)moreInfoAction:(id)sender {
    czzMoreInfoViewController *moreInfoViewController = [czzMoreInfoViewController new];
    moreInfoViewController.forum = self.viewModelManager.forum;
    [self presentViewController:moreInfoViewController animated:YES completion:nil];
}

#pragma mark - Getters
-(czzHomeViewModelManager *)viewModelManager {
    [czzHomeViewModelManager sharedManager].delegate = self;
    return [czzHomeViewModelManager sharedManager];
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
        _tableViewDataSource = [czzHomeTableViewDataSource initWithViewModelManager:self.viewModelManager];
    }
    return _tableViewDataSource;
}

-(czzHomeViewDelegate *)homeViewDelegate {
    if (!_homeViewDelegate) {
        _homeViewDelegate = [czzHomeViewDelegate initWithViewModelManager:self.viewModelManager];
    }
    return _homeViewDelegate;
}

#pragma mark - czzHomeself.viewModelManagerDelegate
- (void)viewModelManagerWantsToReload:(czzHomeViewModelManager *)manager {
    if (manager.threads.count) {
        [self updateTableView];
    }
}

-(void)viewModelManager:(czzHomeViewModelManager *)viewModelManager downloadSuccessful:(BOOL)wasSuccessful {
    DLog(@"%@", NSStringFromSelector(_cmd));
    if (!wasSuccessful && !NavigationManager.isInTransition) {
        [self.refreshControl endRefreshing];
        [self.progressView stopAnimating];
        [self.progressView showWarning];
    }
    self.threadTableView.lastCellType = czzThreadViewCommandStatusCellViewTypeLoadMore;
}

-(void)viewModelManagerBeginDownloading:(czzHomeViewModelManager *)viewModelManager {
    if (!self.progressView.isAnimating)
        [self.progressView startAnimating];
    
}

-(void)viewModelManager:(czzHomeViewModelManager *)list processedThreadData:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    DLog(@"%@", NSStringFromSelector(_cmd));
    // If pageNumber == 1, then is a forum change, scroll to top.
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [self updateTableView];
        [self.refreshControl endRefreshing];
        if (wasSuccessul && self.viewModelManager.pageNumber == 1) {
            [self.threadTableView scrollToTop:NO];
        }

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
    [self.viewModelManager refresh];
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
    self.viewModelManager.forum = selectedForum;
}

#pragma mark - rotation events
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.threadTableView reloadData];
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
