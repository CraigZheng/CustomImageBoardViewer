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
#import "czzCustomForumTableViewManager.h"
#import "czzAddForumTableViewController.h"

#import "CustomImageBoardViewer-Swift.h"

NSString * const kForumPickedNotification = @"ForumNamePicked";
NSString * const kPickedForum = @"PickedForum";

typedef enum : NSUInteger {
    AdvertisementSection = 0,
    ForumSection = 1,
    CustomForumSection = 2,
    ThreadSuggestionSection = 3
} SectionType;

@interface czzForumsViewController () <UITableViewDataSource, UITableViewDelegate, czzPopularThreadsManagerDelegate>
@property (strong, nonatomic) IBOutlet ForumsTableViewManager *forumsTableViewManager;
@property (strong, nonatomic) IBOutlet czzForumsTableViewThreadSuggestionsManager *tableviewThreadSuggestionsManager;
@property (strong, nonatomic) IBOutlet czzCustomForumTableViewManager * customForumTableViewManager;

@property (weak, nonatomic) IBOutlet UITableView *forumsTableView;
@property (weak, nonatomic) IBOutlet UITableView *suggestionTableView;
@property (weak, nonatomic) IBOutlet UITableView *customForumsTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *forumsSegmentedControl;
@property NSDate *lastAdUpdateTime;
@property NSTimeInterval adUpdateInterval;
@property UIView *adCoverView;
@property (assign, nonatomic) BOOL shouldHideCoverView;
@property czzForumManager *forumManager;
@property (strong, nonatomic) czzPopularThreadsManager *popularThreadsManager;
@end

@implementation czzForumsViewController
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
    [bannerView_ setFrame:CGRectMake(0, 0, bannerView_.bounds.size.width,
                                     bannerView_.bounds.size.height)];
//    bannerView_.adUnitID = @"a151ef285f8e0dd";
    bannerView_.adUnitID = @"ca-app-pub-2081665256237089/4247713655";
    bannerView_.rootViewController = self;
    adUpdateInterval = 10 * 60;

    self.tableView.scrollsToTop = NO;
    self.navigationController.navigationBar.barTintColor = [settingCentre barTintColour];
    self.navigationController.navigationBar.tintColor = [settingCentre tintColour];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : self.navigationController.navigationBar.tintColor}];
    
    self.forumManager = [czzForumManager sharedManager];
    self.forumsTableViewManager.forumGroups = self.forumManager.forumGroups;
    self.tableviewThreadSuggestionsManager.popularThreadsManager = self.popularThreadsManager;
    // Reload the forum view when notification from settings centre is received.
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSettingsChangedNotification)
                                                 name:settingsChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidOpen
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [weakSelf reloadDataSources];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:kCustomForumDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [weakSelf reloadDataSources];
                                                  }];
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
    [self reloadDataSources];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.progressView viewDidAppear];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.progressView viewDidDisapper];
}

-(void)refreshForums{
    [self startLoading];
    [self.forumManager updateForums:^(BOOL success, NSError *error) {
        if (!success || error) {
            [self showWarning];
        } else {
            self.forumsTableViewManager.forumGroups = self.forumManager.forumGroups;
        }
        [self reloadDataSources];
        [self stopLoading];
    }];
}

- (void)reloadDataSources {
    [self.forumsTableView reloadData];
    [self.suggestionTableView reloadData];
    [self.customForumsTableView reloadData];
    [self.tableView reloadData];
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
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[czzMoreInfoViewController new]];
    navigationController.restorationIdentifier = NSStringFromClass([UINavigationController class]);
    [NavigationManager.delegate presentViewController:navigationController
                                             animated:YES
                                           completion:nil];
}

#pragma mark -  UITableViewDataSource, UITableViewDelegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    switch (indexPath.section) {
        case AdvertisementSection:
            if (!bannerView_.superview) {
                [self refreshAd];
            }
            if (!shouldHideCoverView) {
                //the cover view
                if (adCoverView.superview) {
                    [adCoverView removeFromSuperview];
                }
                adCoverView = [[UIView alloc] initWithFrame:bannerView_.frame];
                adCoverView.backgroundColor = [settingCentre viewBackgroundColour];
                UILabel *tapMeLabel = [[UILabel alloc] initWithFrame:adCoverView.frame];
                tapMeLabel.text = @"点我，我是广告";
                tapMeLabel.textColor = [settingCentre contentTextColour];
                tapMeLabel.textAlignment = NSTextAlignmentCenter;
                tapMeLabel.userInteractionEnabled = NO;
                [adCoverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCoverView)]];
                [adCoverView addSubview:tapMeLabel];
                [cell.contentView addSubview:bannerView_];
                [cell.contentView addSubview:adCoverView];
            }
            break;
        default:
            break;
    }
    cell.backgroundColor = [settingCentre viewBackgroundColour];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    // Unless the section matches the selected segmented control, or it's the advertisement section,
    // Otherwise return 0.
    if (section - 1 == self.forumsSegmentedControl.selectedSegmentIndex || section == 0) {
        numberOfRows = [super tableView:tableView numberOfRowsInSection:section];
    }
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    // Display the header title only when section is matching the segmented control.
    if (section - 1 == self.forumsSegmentedControl.selectedSegmentIndex || section == 0) {
        title = [super tableView:tableView titleForHeaderInSection:section];
    }
    return title;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case AdvertisementSection:
            return CGRectGetHeight(bannerView_.frame);
            break;
        case ForumSection:
            return self.forumsTableView.contentSize.height;
        case ThreadSuggestionSection: {
            return self.suggestionTableView.contentSize.height;
        }
        case CustomForumSection:
            return self.customForumsTableView.contentSize.height;
        default:
            return UITableViewAutomaticDimension;
            break;
    }
}

#pragma mark - UI actions.
- (IBAction)forumsSegmentedControlValueChanged:(id)sender {
    if (sender == self.forumsSegmentedControl) {
        [self reloadDataSources];
    }
}

#pragma mark - dismiss cover view
-(void)dismissCoverView {
    if (adCoverView && adCoverView.superview) {
        [adCoverView removeFromSuperview];
    }
    shouldHideCoverView = YES;
}

#pragma mark - czzPopularThreadsManagerDelegate

- (void)popularThreadsManagerDidUpdate:(czzPopularThreadsManager *)manager {
    [self reloadDataSources];
}

#pragma mark - Settings changed notification.

- (void)handleSettingsChangedNotification {
    DLog(@"");
    [self reloadDataSources];
}

#pragma mark - Getters

- (czzPopularThreadsManager *)popularThreadsManager {
    if (!_popularThreadsManager) {
        _popularThreadsManager = [[czzPopularThreadsManager alloc] init];
        _popularThreadsManager.delegate = self;
    }
    return _popularThreadsManager;
}

@end
