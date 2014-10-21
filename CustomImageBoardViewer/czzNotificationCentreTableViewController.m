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
#import "czzFeedbackViewController.h"
#import "DACircularProgressView.h"

@interface czzNotificationCentreTableViewController ()<UIDocumentInteractionControllerDelegate>
@property czzNotificationManager *notificationManager;
@property czzImageCentre *imageCentre;
@property NSString *imageFolder;
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
    imageFolder = [czzAppDelegate libraryFolder];
    imageFolder = [imageFolder stringByAppendingPathComponent:@"Thumbnails"];

    notificationManager = [czzNotificationManager new];
    imageCentre = [czzImageCentre sharedInstance];
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
        NSLog(@"%@", exception);
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (czzNotification *notification in notifications) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[czzImageCentre sharedInstance] downloadThumbnailWithURL:notification.thImgSrc isCompletedURL:YES];
        });
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDownloaded:) name:@"ThumbnailDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaderUpdated:) name:@"ImageDownloaderProgressUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
    NSLog(@"tableview content size %@", [NSValue valueWithCGSize:self.tableView.contentSize]);
    NSLog(@"tableview bound size %@", [NSValue valueWithCGSize:self.tableView.bounds.size]);
    [self.view bringSubviewToFront:self.tableView];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notification_text_cell_identifier" forIndexPath:indexPath];
    
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
        czzNotification *selectedNotification = [notifications objectAtIndex:indexPath.row];
        czzFeedbackViewController *feedbackViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedback_view_controller"];
        feedbackViewController.myNotification = selectedNotification;
//        [self.navigationController pushViewController:feedbackViewController animated:YES];
        [[czzAppDelegate sharedAppDelegate].homeViewController pushViewController:feedbackViewController :YES];
        
    }
}

#pragma mark - download tapped images
- (IBAction)userTapInImage:(id)sender {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer*)sender;
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self.tableView];
    NSIndexPath *tapIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    czzNotification *tappedNotification = [notifications objectAtIndex:tapIndexPath.row];
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:tappedNotification.imgSrc.lastPathComponent.lowercaseString])
        {
            [self showDocumentController:file];
            return;
        }
    }
    [[czzImageCentre sharedInstance] downloadImageWithURL:tappedNotification.imgSrc isCompletedURL:YES];
    [[czzAppDelegate sharedAppDelegate] showToast:@"正在下载图片"];
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
            DACircularProgressView *circularProgressView = (DACircularProgressView*)[cellToUpdate viewWithTag:4];
            circularProgressView.progressTintColor = [UIColor whiteColor];
            circularProgressView.trackTintColor = [UIColor grayColor];
            circularProgressView.thicknessRatio = 0.1;
            if (circularProgressView){
                if (imgDownloader.progress < 1)
                {
                    circularProgressView.hidden = NO;
                    circularProgressView.progress = imgDownloader.progress;
                } else {
                    circularProgressView.hidden = YES;
                }
                [circularProgressView setNeedsDisplay];
            }
        }
    }
}

-(void)imageDownloaded:(NSNotification*)notification {
    [self showDocumentController:[notification.userInfo objectForKey:@"FilePath"]];

}
@end
