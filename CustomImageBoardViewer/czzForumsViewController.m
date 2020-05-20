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
NSString * const kPickedTimeline = @"kPickedTimeline";

typedef enum : NSUInteger {
    ForumSection = 0,
    ThreadSuggestionSection,
    CustomForumSection
} SectionType;

@interface czzForumsViewController () <UITableViewDataSource, UITableViewDelegate, czzPopularThreadsManagerDelegate>
@property (strong, nonatomic) IBOutlet ForumsTableViewManager *forumsTableViewManager;
@property (strong, nonatomic) IBOutlet czzForumsTableViewThreadSuggestionsManager *tableviewThreadSuggestionsManager;
@property (strong, nonatomic) IBOutlet czzCustomForumTableViewManager * customForumTableViewManager;

@property (weak, nonatomic) IBOutlet UITableView *forumsTableView;
@property (weak, nonatomic) IBOutlet UITableView *suggestionTableView;
@property (weak, nonatomic) IBOutlet UITableView *customForumsTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *forumsSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *hostSegmentedControl;
@property (strong, nonatomic) NSDate *lastUpdateTime;
@property (assign, nonatomic) NSTimeInterval updateInterval;
@property (assign, nonatomic) BOOL shouldHideCoverView;
@property czzForumManager *forumManager;
@property (strong, nonatomic) czzPopularThreadsManager *popularThreadsManager;
@end

@implementation czzForumsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.updateInterval = 10 * 60;

    self.tableView.scrollsToTop = NO;
    
    self.forumManager = [czzForumManager sharedManager];
    self.forumsTableViewManager.forumGroups = self.forumManager.forumGroups;
    self.tableviewThreadSuggestionsManager.popularThreadsManager = self.popularThreadsManager;
    // Reload the forum view when notification from settings centre is received.
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSettingsChangedNotification)
                                                 name:settingsChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:kCustomForumDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [weakSelf reloadDataSources];
                                                  }];
    [self refreshContent];
    // Schedule a timer to refresh Ad.
    [NSTimer scheduledTimerWithTimeInterval:self.updateInterval / 2
                                     target:self
                                   selector:@selector(refreshContent)
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
        }
        [self reloadDataSources];
        [self stopLoading];
    }];
}

- (void)reloadDataSources {
    [self.forumManager resetForums];
    self.forumsTableViewManager.forumGroups = self.forumManager.forumGroups;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hostSegmentedControl.selectedSegmentIndex = [settingCentre userDefActiveHost];
        [self.forumsTableView reloadData];
        [self.suggestionTableView reloadData];
        [self.customForumsTableView reloadData];
        [self.tableView reloadData];
    });
}

- (void)refreshContent {
    if (!self.lastUpdateTime || [[NSDate new] timeIntervalSinceDate:self.lastUpdateTime] > self.updateInterval) {
        self.lastUpdateTime = [NSDate new];
        [self refreshForums];//might be a good idea to update the forums as well
        [self.popularThreadsManager refreshPopularThreads];
    }
}

- (IBAction)moreInfoAction:(id)sender {
    // Present more info view controller with no selected forum.
    UINavigationController *navigationController = [[CustomAppearanceNavigationController alloc] initWithRootViewController:[czzMoreInfoViewController new]];
    navigationController.restorationIdentifier = NSStringFromClass([UINavigationController class]);
    [NavigationManager.delegate presentViewController:navigationController
                                             animated:YES
                                           completion:nil];
}

#pragma mark -  UITableViewDataSource, UITableViewDelegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [settingCentre viewBackgroundColour];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    // Unless the section matches the selected segmented control, or it's the advertisement section,
    // Otherwise return 0.
    if (section == self.forumsSegmentedControl.selectedSegmentIndex) {
        numberOfRows = [super tableView:tableView numberOfRowsInSection:section];
    }
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
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

- (IBAction)hostsSegmentedControlValueChanged:(UISegmentedControl *)sender {
  switch (sender.selectedSegmentIndex) {
    case 0:
      [settingCentre setUserDefActiveHost:SettingsHostAC];
      break;
    case 1:
      [settingCentre setUserDefActiveHost:SettingsHostBT];
      break;
  }
  [settingCentre saveSettings];
  [self reloadDataSources];
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
