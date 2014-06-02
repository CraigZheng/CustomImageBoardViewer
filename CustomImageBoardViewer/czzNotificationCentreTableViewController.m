//
//  czzNotificationCentreTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotificationCentreTableViewController.h"
#import "czzNotificationManager.h"
#import "czzImageCentre.h"
#import "czzImageDownloader.h"

@interface czzNotificationCentreTableViewController ()
@property czzNotificationManager *notificationManager;
@property czzImageCentre *imageCentre;
@property NSString *thumbnailFolder;
@end

@implementation czzNotificationCentreTableViewController
@synthesize notifications;
@synthesize currentNotification;
@synthesize notificationManager;
@synthesize imageCentre;
@synthesize thumbnailFolder;

- (void)viewDidLoad
{
    [super viewDidLoad];
    thumbnailFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    thumbnailFolder = [thumbnailFolder stringByAppendingPathComponent:@"Thumbnails"];

    notificationManager = [czzNotificationManager new];
    imageCentre = [czzImageCentre sharedInstance];
    if (!notifications) {
        notifications = [NSMutableOrderedSet new];
        NSMutableOrderedSet *cachedSet = [notificationManager checkCachedNotifications];
        if (cachedSet) {
            [notifications addObjectsFromArray:cachedSet.array];
        }
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (czzNotification *notification in notifications) {
        [imageCentre downloadThumbnailWithURL:notification.thImgSrc];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDownloaded:) name:@"ThumbnailDownloaded" object:nil];
}
#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return notifications.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notification_cell_identifier" forIndexPath:indexPath];
    
    // Configure the cell...
    czzNotification *notification = [notifications objectAtIndex:indexPath.row];
    if (cell) {
        UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
        UILabel *descriptionLabel = (UILabel*)[cell viewWithTag:2];
        UIImageView *thImgView = (UIImageView*)[cell viewWithTag:3];
        titleLabel.text = notification.title;
        descriptionLabel.text = notification.description;
        if (notification.thImgSrc.length > 0) {
            NSString *filePath = [thumbnailFolder stringByAppendingPathComponent:[notification.thImgSrc.lastPathComponent stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
            UIImage *previewImage = [[UIImage alloc] initWithContentsOfFile:filePath];
            if (previewImage) {
                thImgView.hidden = NO;
                thImgView.image = previewImage;
            } else {
                thImgView.hidden = YES;
            }
        } else {
            thImgView.hidden = YES;
        }
    }
    return cell;
}


#pragma mark - thumbnail downloaded handler 
-(void)thumbnailDownloaded:(NSNotification*)notif {
//    czzImageDownloader *imgDownloader = [notif.userInfo objectForKey:@"ImageDownloader"];
    BOOL success = [[notif.userInfo objectForKey:@"Success"] boolValue];
    if (!success){
        return;
    }
    [self.tableView reloadData];
}

@end
