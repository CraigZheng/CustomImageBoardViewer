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
    CustomForumSection = 2
} SectionType;

@interface czzForumsViewController () <UITableViewDataSource, UITableViewDelegate, czzPopularThreadsManagerDelegate, czzAddForumTableViewControllerProtocol>
@property (strong, nonatomic) IBOutlet ForumsTableViewManager *forumsTableViewManager;
@property (weak, nonatomic) IBOutlet UITableView *forumsTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *forumsSegmentedControl;
@property NSDate *lastAdUpdateTime;
@property NSTimeInterval adUpdateInterval;
@property UIView *adCoverView;
@property (assign, nonatomic) BOOL shouldHideCoverView;
@property czzForumManager *forumManager;
@property (strong, nonatomic) czzPopularThreadsManager *popularThreadsManager;
@property (strong, nonatomic) czzForumsTableViewThreadSuggestionsManager *tableviewThreadSuggestionsManager;
@property (strong, nonatomic) czzCustomForumTableViewManager * customForumTableViewManager;
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
    // Reload the forum view when notification from settings centre is received.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSettingsChangedNotification)
                                                 name:settingsChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidOpen
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self.tableView reloadData];
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

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.progressView viewDidAppear];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.progressView viewDidDisapper];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *navigationController = segue.destinationViewController;
    if ([navigationController isKindOfClass:[UINavigationController class]] && [navigationController.viewControllers.firstObject isKindOfClass:[czzAddForumTableViewController class]]) {
        [(czzAddForumTableViewController *)navigationController.viewControllers.firstObject setDelegate:self];
    }
}

-(void)refreshForums{
    [self startLoading];
    [self.forumManager updateForums:^(BOOL success, NSError *error) {
        if (!success || error) {
            [self showWarning];
        } else {
            self.forumsTableViewManager.forumGroups = self.forumManager.forumGroups;
        }
        [self.forumsTableView reloadData];
        [self.tableView reloadData];
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
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[czzMoreInfoViewController new]];
    navigationController.restorationIdentifier = NSStringFromClass([UINavigationController class]);
    [NavigationManager.delegate presentViewController:navigationController
                                             animated:YES
                                           completion:nil];
}

#pragma mark -  UITableViewDataSource, UITableViewDelegate

//-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
//    if (!self.forumManager.forumGroups.count)
//        return 1;
//    return self.forumManager.forumGroups.count;
//}
//
//-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    if (!self.forumManager.forumGroups.count)
//        return 1;
//    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:section];
//    if (section == 0)
//    {
//        return forumGroup.forums.count + 1;
//    }
//    return forumGroup.forums.count;
//}
//
//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    if (self.forumManager.forumGroups.count == 0){
//        return nil;
//    }
//    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:section];
//    return forumGroup.area;
//    
//}

#pragma UITableView delegate
//-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSString *cell_identifier = @"forum_cell_identifier";
//    if (!self.forumManager.forumGroups.count){
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"no_service_cell_identifier"];
//        return cell;
//    }
//    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:indexPath.section];
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
//    if (cell){
//        if (indexPath.row < forumGroup.forums.count) {
//            UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
//            titleLabel.textColor = [settingCentre contentTextColour];
//            czzForum *forum = forumGroup.forums[indexPath.row];
//            NSString *displayName = forum.screenName.length ? forum.screenName : forum.name;
//            @try {
//                // Render the displayName as HTML, if anything goes wrong, set it as plain text instead.
//                NSMutableAttributedString *attributedDisplayName = [[NSMutableAttributedString alloc] initWithData: [displayName dataUsingEncoding:NSUTF8StringEncoding]
//                                                                                                           options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
//                                                                                                                     NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
//                                                                                                documentAttributes:nil
//                                                                                                             error:nil];
//                [attributedDisplayName addAttribute:NSFontAttributeName
//                                              value:titleLabel.font
//                                              range:NSMakeRange(0, attributedDisplayName.length)];
//                // If nighty mode, the colour should be changed as well.
//                if (settingCentre.userDefNightyMode) {
//                    [attributedDisplayName addAttribute:NSForegroundColorAttributeName
//                                                  value:settingCentre.contentTextColour
//                                                  range:NSMakeRange(0, attributedDisplayName.length)];
//                }
//                titleLabel.attributedText = attributedDisplayName;
//            } @catch (NSException *exception) {
//                DLog(@"%@", exception);
//                titleLabel.text = displayName;
//            }
//        } else {
//            cell = [tableView dequeueReusableCellWithIdentifier:@"ad_cell_identifier" forIndexPath:indexPath];
//            //position of the ad
//            if (!bannerView_.superview) {
//                [self refreshAd];
//            }
//            if (!shouldHideCoverView) {
//                //the cover view
//                if (adCoverView.superview) {
//                    [adCoverView removeFromSuperview];
//                }
//                adCoverView = [[UIView alloc] initWithFrame:bannerView_.frame];
//                adCoverView.backgroundColor = [UIColor whiteColor];
//                UILabel *tapMeLabel = [[UILabel alloc] initWithFrame:adCoverView.frame];
//                tapMeLabel.text = @"点我，我是广告";
//                tapMeLabel.textAlignment = NSTextAlignmentCenter;
//                tapMeLabel.userInteractionEnabled = NO;
//                [adCoverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCoverView)]];
//                [adCoverView addSubview:tapMeLabel];
//                [cell.contentView addSubview:bannerView_];
//                [cell.contentView addSubview:adCoverView];
//            }
//        }
//    }
//    //background colour - nighty mode enable
//    cell.backgroundColor = [settingCentre viewBackgroundColour];
//    return cell;
//}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.forumManager.forums.count * 44;
}

#pragma mark - UI actions.
- (IBAction)forumsSegmentedControlValueChanged:(id)sender {
    if (sender == self.forumsSegmentedControl) {
        switch (self.forumsSegmentedControl.selectedSegmentIndex) {
            case 0:
                // Set the data source and delegate back to self.
                self.tableView.dataSource = self;
                self.tableView.delegate = self;
                break;
            case 1:
                // Set the data source and delegate to the thread suggestions tableview manager.
                self.tableView.dataSource = self.tableviewThreadSuggestionsManager;
                self.tableView.delegate = self.tableviewThreadSuggestionsManager;
                break;
            case 2:
                // Custom forum table view manager.
                self.tableView.dataSource = self.customForumTableViewManager;
                self.tableView.delegate = self.customForumTableViewManager;
            default:
                break;
        }
        [self.tableView reloadData];
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
    [self.tableView reloadData];
}

#pragma mark - czzAddForumTableViewController

- (void)addForumTableViewControllerDidDismissed:(czzAddForumTableViewController *)viewController {
    [self.tableView reloadData];
}

#pragma mark - Settings changed notification.

- (void)handleSettingsChangedNotification {
    DLog(@"");
    [self.tableView reloadData];
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

- (czzCustomForumTableViewManager *)customForumTableViewManager {
    if (!_customForumTableViewManager) {
        _customForumTableViewManager = [czzCustomForumTableViewManager new];
    }
    return _customForumTableViewManager;
}

@end
