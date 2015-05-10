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

@interface czzForumsViewController () <czzURLDownloaderProtocol, UITableViewDataSource, UITableViewDelegate>
@property czzURLDownloader *xmlDownloader;
@property NSMutableArray *forumGroups;
@property BOOL failedToConnect;
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
@synthesize failedToConnect;
@synthesize bannerView_;
@synthesize lastAdUpdateTime;
@synthesize adUpdateInterval;
@synthesize adCoverView;
@synthesize shouldHideCoverView;
@synthesize forums;
@synthesize progressView;
@synthesize forumManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    forumManager = [czzForumManager sharedInstance];
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
    failedToConnect = NO;
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifdef DEBUG
    versionString = @"DEBUG";
#endif
    NSString *forumString = [[settingCentre forum_list_url] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [NSString stringWithFormat:@"%@-%@", bundleIdentifier, versionString]]];
    NSLog(@"Forum config URL: %@", forumString);
    xmlDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];
    [progressView startAnimating];
    
    //added after the old server is down, this is necessary for the new a isle server
    NSURL *forumURL = [NSURL URLWithString:[settingCentre forum_list_detail_url]];
}

-(NSArray*)parseJsonForForum:(NSData*)jsonData {
    NSError* error;
    NSMutableArray *newForums = [NSMutableArray new];

    NSDictionary *jsonDict;
    if (jsonData)
        jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else {
        error = [NSError errorWithDomain:@"Empty Data" code:999 userInfo:nil];
    }
    if (!error) {
        NSArray *rawForumData = [jsonDict valueForKey:@"forum"];
        for (NSDictionary* rawForum in rawForumData) {
            czzForum *newForum = [[czzForum alloc] initWithJSONDictionary:rawForum];
            if (newForum)
                [newForums addObject:newForum];
        }
    }
    return newForums;
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
    if (failedToConnect)
        return 1;
    return forumGroups.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (failedToConnect)
        return 1;
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:section];
    if (section == 0)
    {
        return forumGroup.forumNames.count + 1;
    }
    return forumGroup.forumNames.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (failedToConnect || forumGroups.count == 0){
        return @" ";
    }
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:section];
    return forumGroup.area;
    
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = @"forum_cell_identifier";
    if (failedToConnect){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"no_service_cell_identifier"];
        return cell;
    }
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        if (indexPath.row < forumGroup.forumNames.count) {
            UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
            titleLabel.textColor = [settingCentre contentTextColour];
            [titleLabel setText:[forumGroup.forumNames objectAtIndex:indexPath.row]];
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
    //avoid index out of bound
    if (indexPath.row >= forums.count)
        return;
    czzForum *pickedForum = [forums objectAtIndex:indexPath.row];
    [self.viewDeckController toggleLeftViewAnimated:YES];
    //POST a local notification to inform other view controllers that a new forum is picked
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setObject:pickedForum forKey:kPickedForum];
    [[NSNotificationCenter defaultCenter] postNotificationName:kForumPickedNotification object:self userInfo:userInfo];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //ad cell
    if (indexPath.section == 0 && indexPath.row == [forumGroups.lastObject forumNames].count) {
        return bannerView_.bounds.size.height;
    }
    return 44;
}

#pragma czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    if (successed){
        NSArray *defaultForums = [self parseJsonForForum:xmlData];
        forums = [NSMutableArray arrayWithArray:defaultForums];
        //TODO absort the parsed forums
    } else {
        failedToConnect = YES;
    }
    [progressView stopAnimating];
    [forumsTableView reloadData];
}

#pragma mark - dismiss cover view
-(void)dismissCoverView {
    if (adCoverView && adCoverView.superview) {
        [adCoverView removeFromSuperview];
    }
    shouldHideCoverView = YES;
}

#pragma XML parser
-(void)parseModel:(SMXMLElement*)model{
    for (SMXMLElement *child in model.children) {
        if ([child.name isEqualToString:@"ArrayOfForumGroup"]){
            for (SMXMLElement *forumGroup in child.children) {
                [self parseForumGroup:forumGroup];
            }
        }
    }
}

-(void)parseForumGroup:(SMXMLElement*)forumGroup{
    czzForumGroup *newForumGroup = [czzForumGroup new];
    for (SMXMLElement *child in forumGroup.children) {
        if ([child.name isEqualToString:@"Area"]){
            newForumGroup.area = child.value;
        } else if ([child.name isEqualToString:@"ForumNames"]){
            //each children would be a name of a forum
            for (SMXMLElement *forum in child.children) {
                [newForumGroup.forumNames addObject:forum.value];
            }
        }
    }
    [forumGroups addObject:newForumGroup];
}


@end
