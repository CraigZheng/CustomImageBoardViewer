//
//  czzForumsViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumsViewController.h"
#import "czzThread.h"
#import "czzURLDownloader.h"
#import "czzForumGroup.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"
#import "czzForumManager.h"
#import "GSIndeterminateProgressView.h"

@interface czzForumsViewController () <czzForumManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property czzURLDownloader *xmlDownloader;
@property NSMutableArray *forumGroups;
@property NSDate *lastAdUpdateTime;
@property NSTimeInterval adUpdateInterval;
@property UIView *adCoverView;
@property BOOL shouldHideCoverView;
@property GSIndeterminateProgressView *progressView;
@property czzForumManager *forumManager;
@end

@implementation czzForumsViewController
@synthesize xmlDownloader;
@synthesize forumsTableView;
@synthesize forumGroups;
@synthesize bannerView_;
@synthesize lastAdUpdateTime;
@synthesize adUpdateInterval;
@synthesize adCoverView;
@synthesize shouldHideCoverView;
@synthesize progressView;
@synthesize forumManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    forumManager = [czzForumManager sharedManager];
    forumGroups = [NSMutableArray new];
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

    //assign data source
    forumGroups = forumManager.allForumGroups;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    [self.forumsTableView reloadData];
    [self refreshAd];
}

-(void)refreshForums{
    [forumManager updateForum];
}

-(void)refreshAd {
    if (!lastAdUpdateTime || [[NSDate new] timeIntervalSinceDate:lastAdUpdateTime] > adUpdateInterval) {
        [bannerView_ loadRequest:[GADRequest request]];
        lastAdUpdateTime = [NSDate new];
        [self refreshForums];//might be a good idea to update the forums as well
    }
}

#pragma UITableView datasouce
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return forumGroups.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:section];
    if (section == 0)
    {
        return [forumGroup availableForums].count + 1;
    }
    return [forumGroup availableForums].count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (forumGroups.count == 0){
        return @" ";
    }
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:section];
    return forumGroup.area;
    
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = @"forum_cell_identifier";
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        if (indexPath.row < [forumGroup availableForums].count) {
            czzForum *forum = [[forumGroup availableForums] objectAtIndex:indexPath.row];
            UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
            titleLabel.textColor = [settingCentre contentTextColour];
            [titleLabel setText:forum.name];
        }
        //last cell of the first section should be the ad cell
        else {
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
    //avoid index out of bound
    if (indexPath.row >= [[forumGroups objectAtIndex:indexPath.section] availableForums].count)
        return;
    czzForum *pickedForum = [[[forumGroups objectAtIndex:indexPath.section] availableForums] objectAtIndex:indexPath.row];
    [self.viewDeckController toggleLeftViewAnimated:YES];
    //POST a local notification to inform other view controllers that a new forum is picked
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setObject:pickedForum forKey:kPickedForum];
    [[NSNotificationCenter defaultCenter] postNotificationName:kForumPickedNotification object:self userInfo:userInfo];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //ad cell
    if (indexPath.section == 0 && indexPath.row == [[forumGroups objectAtIndex:indexPath.section] availableForums].count) {
        return bannerView_.bounds.size.height;
    }
    return 44;
}

#pragma mark - czzForumManagerDelegate
-(void)forumManager:(czzForumManager *)manager updated:(BOOL)wasSuccessful {
    if (wasSuccessful) {
        [forumsTableView reloadData];
    }
    [progressView stopAnimating];
}

-(void)forumManagerDidStartUpdate:(czzForumManager *)manager {
    [progressView startAnimating];
}

#pragma mark - dismiss cover view
-(void)dismissCoverView {
    if (adCoverView && adCoverView.superview) {
        [adCoverView removeFromSuperview];
    }
    shouldHideCoverView = YES;
}

@end
