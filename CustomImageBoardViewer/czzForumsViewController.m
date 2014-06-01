//
//  czzForumsViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumsViewController.h"
#import "czzThread.h"
#import "czzXMLDownloader.h"
#import "czzForumGroup.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"

@interface czzForumsViewController () <czzXMLDownloaderDelegate, UITableViewDataSource, UITableViewDelegate>
@property czzXMLDownloader *xmlDownloader;
@property NSMutableArray *forumGroups;
@property BOOL failedToConnect;
@property NSDate *lastAdUpdateTime;
@property NSTimeInterval adUpdateInterval;
@property UIView *coverView;
@end

@implementation czzForumsViewController
@synthesize xmlDownloader;
@synthesize forumsTableView;
@synthesize forumGroups;
@synthesize failedToConnect;
@synthesize bannerView_;
@synthesize lastAdUpdateTime;
@synthesize adUpdateInterval;
@synthesize coverView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    forumGroups = [NSMutableArray new];
    [self refreshForums];
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    bannerView_.adUnitID = @"a151ef285f8e0dd";
    bannerView_.rootViewController = self;
    adUpdateInterval = 5 * 60;
}

-(void)refreshForums{
    failedToConnect = NO;
    if (xmlDownloader)
        [xmlDownloader stop];
    //NSString *forumString = @"http://civ.my-realm.com/forums.xml";
    NSString *forumString = [[czzAppDelegate sharedAppDelegate].myhost stringByAppendingPathComponent:@"forums.xml"];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];
    [self.view makeToastActivity];
}

-(void)refreshAd {
    if (!lastAdUpdateTime || [[NSDate new] timeIntervalSinceDate:lastAdUpdateTime] > adUpdateInterval) {
        [bannerView_ loadRequest:[GADRequest request]];
        lastAdUpdateTime = [NSDate new];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self refreshAd];
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
    if (section == forumGroups.count - 1)
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
        return [tableView dequeueReusableCellWithIdentifier:@"no_service_cell_identifier"];
    }
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        if (indexPath.row < forumGroup.forumNames.count) {
            UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
            [titleLabel setText:[forumGroup.forumNames objectAtIndex:indexPath.row]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ad_cell_identifier" forIndexPath:indexPath];

            //position of the ad
            if (!bannerView_.superview) {
                [bannerView_ setFrame:CGRectMake(0, 0, bannerView_.bounds.size.width,
                                                 bannerView_.bounds.size.height)];
                [self refreshAd];
            }
            //the cover view
            if (coverView.superview) {
                [coverView removeFromSuperview];
            }
            coverView = [[UIView alloc] initWithFrame:bannerView_.frame];
            coverView.backgroundColor = [UIColor whiteColor];
            UILabel *tapMeLabel = [[UILabel alloc] initWithFrame:coverView.frame];
            tapMeLabel.text = @"点我，我是广告";
            tapMeLabel.textAlignment = NSTextAlignmentCenter;
            tapMeLabel.userInteractionEnabled = NO;
            [coverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCoverView)]];
            [coverView addSubview:tapMeLabel];
            [cell.contentView addSubview:bannerView_];
            [cell.contentView addSubview:coverView];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (failedToConnect){
        [self refreshForums];
        return;
    }
    if (forumGroups.count == 0)
        return;
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:indexPath.section];
    if (indexPath.row >= forumGroup.forumNames.count)
        return;
    NSString *forumName = [forumGroup.forumNames objectAtIndex:indexPath.row];
    [self.viewDeckController toggleLeftViewAnimated:YES];
    //POST a local notification to inform other view controllers that a new forum is picked
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setObject:forumName forKey:@"ForumName"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ForumNamePicked" object:self userInfo:userInfo];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //ad cell
    if (indexPath.section == forumGroups.count - 1 && indexPath.row == [forumGroups.lastObject forumNames].count) {
        return bannerView_.bounds.size.height;
    }
    return tableView.rowHeight;
}

#pragma czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    if (successed){
        forumGroups = [NSMutableArray new];
        //parse the return XML object
        NSError *error;
        SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
        if (error){
            NSLog(@"%@", error);
            return;
        }
        NSArray *children = [xmlDoc.root children];
        for (SMXMLElement *child in children){
            //parse the result
            if ([child.name isEqualToString:@"status"]){
                NSInteger status = [child.value integerValue];
                if (status != 200){
                    [self.view makeToast:@"网络错误：无法接上服务器" duration:1.5 position:@"bottom" image:[UIImage imageNamed:@"warning"]];
                    break;
                }
            }
            //parse the model
            if ([child.name isEqualToString:@"model"]){
                [self parseModel:child];
            }
        }
    }
    [self.view hideToastActivity];
    if (forumGroups.count <= 0)
        failedToConnect = YES;
    [forumsTableView reloadData];
}

#pragma mark - dismiss cover view
-(void)dismissCoverView {
    if (coverView && coverView.superview) {
        [coverView removeFromSuperview];
    }
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
