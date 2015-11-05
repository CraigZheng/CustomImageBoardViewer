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
#import "GSIndeterminateProgressView.h"
#import "czzMoreInfoViewController.h"

NSString * const kForumPickedNotification = @"ForumNamePicked";
NSString * const kPickedForum = @"PickedForum";

@interface czzForumsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (assign, nonatomic) BOOL failedToConnect;
@property NSDate *lastAdUpdateTime;
@property NSTimeInterval adUpdateInterval;
@property UIView *adCoverView;
@property (assign, nonatomic) BOOL shouldHideCoverView;
@property GSIndeterminateProgressView *progressView;
@property czzForumManager *forumManager;
@end

@implementation czzForumsViewController
@synthesize forumsTableView;
@synthesize failedToConnect;
@synthesize bannerView_;
@synthesize lastAdUpdateTime;
@synthesize adUpdateInterval;
@synthesize adCoverView;
@synthesize shouldHideCoverView;
@synthesize forums;
@synthesize progressView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self refreshForums];
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
//    bannerView_.adUnitID = @"a151ef285f8e0dd";
    bannerView_.adUnitID = @"ca-app-pub-2081665256237089/4247713655";
    bannerView_.rootViewController = self;
    adUpdateInterval = 10 * 60;

    self.navigationController.navigationBar.barTintColor = [settingCentre barTintColour];
    self.navigationController.navigationBar.tintColor = [settingCentre tintColour];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : self.navigationController.navigationBar.tintColor}];
    
    progressView = [[GSIndeterminateProgressView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 2, self.navigationController.navigationBar.frame.size.width, 2)];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.navigationController.navigationBar addSubview:progressView];

    self.forumManager = [czzForumManager sharedManager];
    [self refreshForums];
}


-(void)viewWillAppear:(BOOL)animated{
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [super viewWillAppear:animated];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self.forumsTableView reloadData];
    [self refreshAd];
}

-(void)refreshForums{
    [self.progressView startAnimating];
    [self.forumManager updateForums:^(BOOL success, NSError *error) {
        failedToConnect = !success;
        [self.forumsTableView reloadData];
        [self.progressView stopAnimating];
    }];
}

-(void)refreshAd {
    if (!lastAdUpdateTime || [[NSDate new] timeIntervalSinceDate:lastAdUpdateTime] > adUpdateInterval) {
        [bannerView_ loadRequest:[GADRequest request]];
        lastAdUpdateTime = [NSDate new];
        [self refreshForums];//might be a good idea to update the forums as well
    }
}

- (IBAction)moreInfoAction:(id)sender {
    // Present more info view controller with no selected forum.
    UIViewController *topViewContorller = [UIApplication topViewController];
    [topViewContorller presentViewController:[[UINavigationController alloc] initWithRootViewController:[czzMoreInfoViewController new]] animated:YES completion:nil];
}

#pragma UITableView datasouce
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (failedToConnect)
        return 1;
    return self.forumManager.forumGroups.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (failedToConnect)
        return 1;
    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:section];
    if (section == 0)
    {
        return forumGroup.forums.count + 1;
    }
    return forumGroup.forums.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (failedToConnect || self.forumManager.forumGroups.count == 0){
        return @" ";
    }
    czzForumGroup *forumGroup = [self.forumManager.forumGroups objectAtIndex:section];
    return forumGroup.area;
    
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = @"forum_cell_identifier";
    if (failedToConnect){
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
    if (failedToConnect){
        [self refreshForums];
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

@end
