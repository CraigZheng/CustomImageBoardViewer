//
//  czzNotificationCentreTableViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotificationCentreTableViewController.h"
#import "czzNotificationManager.h"
#import "czzNavigationController.h"
#import "czzNotificationBannerViewController.h"
#import "czzImageCacheManager.h"
#import "czzImageDownloaderManager.h"
#import "czzImageDownloader.h"
#import "czzFeedbackViewController.h"
#import "czzURLHandler.h"
#import "czzNoSelectionTextView.h"

@interface czzNotificationCentreTableViewController ()<UIDocumentInteractionControllerDelegate>
@property czzNotificationManager *notificationManager;
@property czzImageCacheManager *imageCentre;
@property (strong, nonatomic) NSString *imageFolder;
@property UIDocumentInteractionController *documentInteractionController;
@end

@implementation czzNotificationCentreTableViewController
@synthesize notifications;
@synthesize currentNotification;
@synthesize notificationManager;
@synthesize imageCentre;
@synthesize imageFolder;
@synthesize documentInteractionController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"通知中心";
    self.hidesBottomBarWhenPushed = YES;
    imageFolder = [czzAppDelegate libraryFolder];
    imageFolder = [imageFolder stringByAppendingPathComponent:@"Thumbnails"];

    notificationManager = [czzNotificationManager new];
    imageCentre = [czzImageCacheManager sharedInstance];
    if (!notifications) {
        notifications = [NSMutableOrderedSet new];
        NSMutableOrderedSet *cachedSet = [notificationManager checkCachedNotifications];
        if (cachedSet) {
            [notifications addObjectsFromArray:cachedSet.array];
        }
    }
    @try {
        NSArray *sortedArray = [notifications.array sortedArrayUsingComparator: ^(id a, id b) {
            NSInteger id1 = [(czzNotification*)a notificationID].integerValue;
            NSInteger id2 = [(czzNotification*)b notificationID].integerValue;
            if (id2 > id1)
                return (NSComparisonResult)NSOrderedDescending;
            else if (id2 < id1)
                return (NSComparisonResult)NSOrderedAscending;
            else
                return (NSComparisonResult)NSOrderedSame;
        }];
        notifications = [NSMutableOrderedSet orderedSetWithArray:sortedArray];
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (czzNotification *notification in notifications) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[czzImageDownloaderManager sharedManager] downloadImageWithURL:notification.imgSrc isThumbnail:NO];
        });
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDownloaded:) name:@"ThumbnailDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaderUpdated:) name:@"ImageDownloaderProgressUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
    DDLogDebug(@"tableview content size %@", [NSValue valueWithCGSize:self.tableView.contentSize]);
    DDLogDebug(@"tableview bound size %@", [NSValue valueWithCGSize:self.tableView.bounds.size]);
    [self.view bringSubviewToFront:self.tableView];
    
    //dismiss banner view - if any
    czzNotificationBannerViewController *bannerViewController = [(czzNavigationController*)self.navigationController notificationBannerViewController];
    if (bannerViewController) {
        [bannerViewController dismissAction:nil];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return notifications.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"notification_text_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.tag = 1;
        titleLabel.font = [UIFont systemFontOfSize:10];
        titleLabel.textColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:1];
        [cell.contentView addSubview:titleLabel];

        czzNoSelectionTextView *bodyView = [[czzNoSelectionTextView alloc] init];
        bodyView.translatesAutoresizingMaskIntoConstraints = NO;
        bodyView.tag = 2;
        bodyView.scrollEnabled = NO;
        bodyView.editable = NO;
        bodyView.userInteractionEnabled = NO;
        bodyView.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        bodyView.dataDetectorTypes = UIDataDetectorTypeLink;
        bodyView.textContainerInset = UIEdgeInsetsZero;
        bodyView.textContainer.lineFragmentPadding = 0;
        [cell.contentView addSubview:bodyView];

        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:1],
            [titleLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:3],
            [bodyView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:13],
            [bodyView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
            [bodyView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
            [cell.contentView.bottomAnchor constraintEqualToAnchor:bodyView.bottomAnchor constant:2]
        ]];
    }
    
    // Configure the cell...
    czzNotification *notification = [notifications objectAtIndex:indexPath.row];
    if (cell) {
        UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
        UITextView *descriptionTextView = (UITextView*)[cell viewWithTag:2];
        titleLabel.text = notification.title;
        descriptionTextView.text = notification.content;
    }
    return cell;
}



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < notifications.count)
    {
        czzNotification *notification = [notifications objectAtIndex:indexPath.row];
        CGFloat preferHeight = 0;
        
        UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        newHiddenTextView.hidden = YES;
        [self.view addSubview:newHiddenTextView];
        newHiddenTextView.font = [UIFont systemFontOfSize:16];
        newHiddenTextView.text = notification.content;
        preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height;
        [newHiddenTextView removeFromSuperview];

        preferHeight += 20;
//        if (notification.thImgSrc.length > 0) {
//            preferHeight += 80;
//        }
        return MAX(preferHeight, tableView.rowHeight);
    }
    return tableView.rowHeight;
}

#pragma mark - UITableViewControllerDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < notifications.count) {
        currentNotification = [notifications objectAtIndex:indexPath.row];
        if (currentNotification.link.length > 0)
        {
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"链接：%@", currentNotification.link]
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"打开链接"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [czzURLHandler handleURL:[NSURL URLWithString:self->currentNotification.link]];
                                                          }]];
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"反馈"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self presentFeedbackViewControllerWithNotification:self->currentNotification];
                                                          }]];
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            actionSheet.popoverPresentationController.sourceView = self.view;
            actionSheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
                                                                             CGRectGetMidY(self.view.bounds), 1, 1);
            [self presentViewController:actionSheet animated:YES completion:nil];
        } else {
            [self presentFeedbackViewControllerWithNotification:currentNotification];
        }
    }
}

-(void)presentFeedbackViewControllerWithNotification:(czzNotification*)notification {
    czzFeedbackViewController *feedbackViewController = [czzFeedbackViewController new];
    feedbackViewController.myNotification = notification;
    [self.navigationController pushViewController:feedbackViewController animated:YES];

}

//show documentcontroller
-(void)showDocumentController:(NSString*)path{
    if (path){
        if (self.isViewLoaded && self.view.window) {
            if (documentInteractionController) {
                [documentInteractionController dismissPreviewAnimated:YES];
            }
            documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
            documentInteractionController.delegate = self;
            [documentInteractionController presentPreviewAnimated:YES];
            
        }
    }
}

#pragma mark UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
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

#pragma mark notification handler - image downloading progress update
-(void)imageDownloaderUpdated:(NSNotification*)notification{
    czzImageDownloader *imgDownloader = [notification.userInfo objectForKey:@"ImageDownloader"];
    if (imgDownloader){
        NSInteger updateIndex = -1;
        for (czzNotification *myNotification in notifications) {
            if ([myNotification.imgSrc isEqualToString:imgDownloader.targetURLString]){
                updateIndex = [notifications indexOfObject:myNotification];
                break;
            }
        }
        if (updateIndex > -1){
            UITableViewCell *cellToUpdate = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:updateIndex inSection:0]];
            UIProgressView *progressView = (UIProgressView *)[cellToUpdate viewWithTag:4];
            if ([progressView isKindOfClass:[UIProgressView class]]) {
                progressView.progressTintColor = [UIColor whiteColor];
                progressView.trackTintColor = [UIColor grayColor];
                if (imgDownloader.progress < 1) {
                    progressView.hidden = NO;
                    progressView.progress = imgDownloader.progress;
                } else {
                    progressView.hidden = YES;
                }
            }
        }
    }
}

-(void)imageDownloaded:(NSNotification*)notification {
    [self showDocumentController:[notification.userInfo objectForKey:@"FilePath"]];

}

+ (instancetype)new {
    return [[self alloc] initWithStyle:UITableViewStylePlain];
}

@end
