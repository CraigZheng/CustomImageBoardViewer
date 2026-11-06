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
#import "czzMoreInfoViewController.h"
#import "czzCustomForumTableViewManager.h"
#import "czzAddForumTableViewController.h"

#import "CustomImageBoardViewer-Swift.h"

NSString * const kForumPickedNotification = @"ForumNamePicked";
NSString * const kPickedForum = @"PickedForum";
NSString * const kPickedTimeline = @"kPickedTimeline";

typedef enum : NSUInteger {
    ForumSection = 0,
    CustomForumSection
} SectionType;

@interface czzForumsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) ForumsTableViewManager *forumsTableViewManager;
@property (strong, nonatomic) czzCustomForumTableViewManager * customForumTableViewManager;

@property (strong, nonatomic) UITableView *forumsTableView;
@property (strong, nonatomic) UITableView *customForumsTableView;
@property (strong, nonatomic) UIView *adView;
@property (strong, nonatomic) NSDate *lastUpdateTime;
@property (assign, nonatomic) NSTimeInterval updateInterval;
@property (assign, nonatomic) BOOL shouldHideCoverView;
@property czzForumManager *forumManager;
@property (strong, nonatomic) NSObject *customForumObserver;
@end

@implementation czzForumsViewController

- (void)dealloc {
    if (self.customForumObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.customForumObserver];
        self.customForumObserver = nil;
    }
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.updateInterval = 10 * 60;
    [self installForumMenu];

    self.tableView.scrollsToTop = NO;
    
    self.forumManager = [czzForumManager sharedManager];
    self.forumsTableViewManager.forumGroups = self.forumManager.forumGroups;
    // Reload the forum view when notification from settings centre is received.
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSettingsChangedNotification)
                                                 name:settingsChangedNotification
                                               object:nil];
    self.customForumObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kCustomForumDidChangeNotification
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
        [self.forumsTableView reloadData];
        [self.customForumsTableView reloadData];
        [self.tableView reloadData];
    });
}

- (void)refreshContent {
    if (!self.lastUpdateTime || [[NSDate new] timeIntervalSinceDate:self.lastUpdateTime] > self.updateInterval) {
        self.lastUpdateTime = [NSDate new];
        [self refreshForums];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UITableView *nestedTableView = [self nestedTableForSection:indexPath.section];
    [nestedTableView removeFromSuperview];
    nestedTableView.translatesAutoresizingMaskIntoConstraints = YES;
    nestedTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    nestedTableView.frame = cell.contentView.bounds;
    [cell.contentView addSubview:nestedTableView];
    cell.backgroundColor = [settingCentre viewBackgroundColour];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Forum / custom-forum segmented control was removed; keep the old
    // default of showing only the forums section.
    return section == ForumSection ? 1 : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ForumSection:
            return self.forumsTableView.contentSize.height;
        case CustomForumSection:
            return self.customForumsTableView.contentSize.height;
        default:
            return UITableViewAutomaticDimension;
            break;
    }
}

#pragma mark - Settings changed notification.

- (void)handleSettingsChangedNotification {
    DLog(@"");
    [self reloadDataSources];
}

- (void)installForumMenu {
    self.tableView.backgroundColor = [UIColor colorWithRed:0.9490196078 green:0.9490196078 blue:0.968627451 alpha:1];
    self.tableView.sectionHeaderHeight = 28;
    self.tableView.sectionFooterHeight = 28;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    headerView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.tableHeaderView = headerView;
    self.adView = headerView;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    footerView.hidden = YES;
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;

    self.forumsTableViewManager = [ForumsTableViewManager new];
    self.customForumTableViewManager = [czzCustomForumTableViewManager new];
    self.forumsTableView = [self embeddedGroupedTableWithDataSource:self.forumsTableViewManager];
    self.customForumsTableView = [self embeddedGroupedTableWithDataSource:self.customForumTableViewManager];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moreInfoAction:)];
}

- (UITableView *)embeddedGroupedTableWithDataSource:(id<UITableViewDataSource, UITableViewDelegate>)dataSource {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.scrollEnabled = NO;
    tableView.alwaysBounceVertical = YES;
    tableView.rowHeight = 44;
    tableView.sectionHeaderHeight = 18;
    tableView.sectionFooterHeight = 18;
    tableView.backgroundColor = [UIColor colorWithRed:0.9490196078 green:0.9490196078 blue:0.968627451 alpha:1];
    tableView.dataSource = dataSource;
    tableView.delegate = dataSource;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    footerView.hidden = YES;
    footerView.backgroundColor = [UIColor clearColor];
    tableView.tableFooterView = footerView;
    return tableView;
}

- (UITableView *)nestedTableForSection:(NSInteger)section {
    switch (section) {
        case CustomForumSection:
            return self.customForumsTableView;
        default:
            return self.forumsTableView;
    }
}

@end
