//
//  czzForumsViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumsViewController.h"
#import "czzThread.h"
#import "czzForumGroup.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"
#import "czzForum.h"
#import "czzForumManager.h"
#import "czzPopularThreadsManager.h"
#import "czzMoreInfoViewController.h"
#import "czzForumsTableViewThreadSuggestionsManager.h"

NSString * const kForumPickedNotification = @"ForumNamePicked";
NSString * const kPickedForum = @"PickedForum";

@interface czzForumsViewController () <UITableViewDataSource, UITableViewDelegate, czzPopularThreadsManagerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *forumsSegmentedControl;
@property NSDate *lastAdUpdateTime;
@property NSTimeInterval adUpdateInterval;
@property UIView *adCoverView;
@property (assign, nonatomic) BOOL shouldHideCoverView;
@property czzForumManager *forumManager;
@property (strong, nonatomic) czzPopularThreadsManager *popularThreadsManager;
@property (strong, nonatomic) czzForumsTableViewThreadSuggestionsManager *tableviewThreadSuggestionsManager;
@end

@implementation czzForumsViewController
@synthesize forumsTableView;
@synthesize bannerView_;
@synthesize lastAdUpdateTime;
@synthesize adUpdateInterval;
@synthesize adCoverView;
@synthesize shouldHideCoverView;
@synthesize forums;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
//    bannerView_.adUnitID = @"a151ef285f8e0dd";
    bannerView_.adUnitID = @"ca-app-pub-2081665256237089/4247713655";
    bannerView_.rootViewController = self;
    adUpdateInterval = 10 * 60;

    self.forumsTableView.scrollsToTop = NO;
    self.navigationController.navigationBar.barTintColor = [settingCentre barTintColour];
    self.navigationController.navigationBar.tintColor = [settingCentre tintColour];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : self.navigationController.navigationBar.tintColor}];
    
    self.forumManager = [czzForumManager sharedManager];
    // Reload the forum view when notification from settings centre is received.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSettingsChangedNotification)
                                                 name:settingsChangedNotification
                                               object:nil];
    [self refreshAd];
    // Schedule a timer to refresh Ad.
    [NSTimer scheduledTimerWithTimeInterval:adUpdateInterval / 2
                                     target:self
                                   selector:@selector(refreshAd)
                                   userInfo:nil
                                    repeats:YES];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self.forumsTableView reloadData];
}

-(void)refreshForums{
    [self startLoading];
    [self.forumManager updateForums:^(BOOL success, NSError *error) {
        [self.forumsTableView reloadData];
        [self stopLoading];
    }];
}

- (void)refreshPopularThreads {
    [self.popularThreadsManager refreshPopularThreads];
}

-(void)refreshAd {
    DLog(@"");
    if (!lastAdUpdateTime || [[NSDate new] timeIntervalSinceDate:lastAdUpdateTime] > adUpdateInterval) {
        [bannerView_ loadRequest:[GADRequest request]];
        lastAdUpdateTime = [NSDate new];
        [self refreshForums];//might be a good idea to update the forums as well
        [self refreshPopularThreads];
    }
}

- (IBAction)moreInfoAction:(id)sender {
    // Present more info view controller with no selected forum.
    UIViewController *topViewContorller = [UIApplication topViewController];
    [topViewContorller presentViewController:[[UINavigationController alloc] initWithRootViewController:[czzMoreInfoViewController new]] animated:YES completion:nil];
}

#pragma UITableView datasouce
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (!self.forumManager.forumGroups.count)
        return 1;
    return self.forumManager.forumGroups.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (!self.forumManager.forumGroups.count)
        return 1;
    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:section];
    if (section == 0)
    {
        return forumGroup.forums.count + 1;
    }
    return forumGroup.forums.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (self.forumManager.forumGroups.count == 0){
        return @" ";
    }
    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:section];
    return forumGroup.area;
    
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = @"forum_cell_identifier";
    if (!self.forumManager.forumGroups.count){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"no_service_cell_identifier"];
        return cell;
    }
    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        if (indexPath.row < forumGroup.forums.count) {
            UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
            titleLabel.textColor = [settingCentre contentTextColour];
            [titleLabel setText:[[forumGroup.forums objectAtIndex:indexPath.row] name]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ad_cell_identifier" forIndexPath:indexPath];
            //position of the ad
            if (!bannerView_.superview) {
                [bannerView_ setFrame:CGRectMake(0, 0, bannerView_.bounds.size.width,
                                                 bannerView_.bounds.size.height)];
                [self refreshAd];
            }
            if (!shouldHideCoverView) {
                //the cover view
                if (adCoverView.superview) {
                    [adCoverView removeFromSuperview];
                }
                adCoverView = [[UIView alloc] initWithFrame:bannerView_.frame];
                adCoverView.backgroundColor = [UIColor whiteColor];
                UILabel *tapMeLabel = [[UILabel alloc] initWithFrame:adCoverView.frame];
                tapMeLabel.text = @"点我，我是广告";
                tapMeLabel.textAlignment = NSTextAlignmentCenter;
                tapMeLabel.userInteractionEnabled = NO;
                [adCoverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCoverView)]];
                [adCoverView addSubview:tapMeLabel];
                [cell.contentView addSubview:bannerView_];
                [cell.contentView addSubview:adCoverView];
            }
        }
    }
    //background colour - nighty mode enable
    cell.backgroundColor = [settingCentre viewBackgroundColour];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.forumManager.forumGroups.count){
        [self refreshForums];
        [self refreshPopularThreads];
        return;
    }
    if (self.forumManager.forumGroups.count == 0)
        return;
    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:indexPath.section];
    if (indexPath.row >= forumGroup.forums.count)
        return;
    czzForum *forum = [forumGroup.forums objectAtIndex:indexPath.row];
    [self.viewDeckController toggleLeftViewAnimated:YES];
    //POST a local notification to inform other view controllers that a new forum is picked
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setObject:forum forKey:kPickedForum];
    [[NSNotificationCenter defaultCenter] postNotificationName:kForumPickedNotification object:self userInfo:userInfo];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //ad cell
    if (indexPath.section == 0 && indexPath.row == [self.forumManager.forumGroups.lastObject forums].count) {
        return bannerView_.bounds.size.height;
    }
    return 44;
}

#pragma mark - UI actions.
- (IBAction)forumsSegmentedControlValueChanged:(id)sender {
    if (sender == self.forumsSegmentedControl) {
        switch (self.forumsSegmentedControl.selectedSegmentIndex) {
            case 0:
                // Set the data source and delegate back to self.
                self.forumsTableView.dataSource = self;
                self.forumsTableView.delegate = self;
                break;
            case 1:
                // Set the data source and delegate to the thread suggestions tableview manager.
                self.forumsTableView.dataSource = self.tableviewThreadSuggestionsManager;
                self.forumsTableView.delegate = self.tableviewThreadSuggestionsManager;
                break;
            default:
                break;
        }
        [self.forumsTableView reloadData];
    }
}

#pragma mark - dismiss cover view
-(void)dismissCoverView {
    if (adCoverView && adCoverView.superview) {
        [adCoverView removeFromSuperview];
    }
    shouldHideCoverView = YES;
}

#pragma mark - IIViewDeckControllerDelegate

- (void)viewDeckController:(IIViewDeckController *)viewDeckController willOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    // Notify about the view will appear event.
    [self viewWillAppear:animated];
}

#pragma mark - czzPopularThreadsManagerDelegate

- (void)popularThreadsManagerDidUpdate:(czzPopularThreadsManager *)manager {
    [self.forumsTableView reloadData];
}

#pragma mark - Settings changed notification.

- (void)handleSettingsChangedNotification {
    DLog(@"");
    [self.forumsTableView reloadData];
}

#pragma mark - Getters

- (czzPopularThreadsManager *)popularThreadsManager {
    if (!_popularThreadsManager) {
        _popularThreadsManager = [[czzPopularThreadsManager alloc] init];
        _popularThreadsManager.delegate = self;
    }
    return _popularThreadsManager;
}

- (czzForumsTableViewThreadSuggestionsManager *)tableviewThreadSuggestionsManager {
    if (!_tableviewThreadSuggestionsManager) {
        _tableviewThreadSuggestionsManager = [[czzForumsTableViewThreadSuggestionsManager alloc] initWithPopularThreadsManager:self.popularThreadsManager];
    }
    return _tableviewThreadSuggestionsManager;
}

@end
