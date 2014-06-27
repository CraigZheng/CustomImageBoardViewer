//
//  czzNotificationBannerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotificationBannerViewController.h"
#import "czzAppDelegate.h"
#import "czzNotificationDownloader.h"
#import "czzNotificationManager.h"
#import "czzNotificationCentreTableViewController.h"

@interface czzNotificationBannerViewController ()<czzNotificationDownloaderDelegate>
@property NSTimer *updateTextTimer;
@property czzNotificationDownloader *notificationDownloader;
@property NSDate *lastUpdateTime;
@property NSTimer *downloadNotificationTimer;
@property NSInteger currentNotificationIndex;
@property czzNotificationManager *notificationManager;
@property (nonatomic) NSString *cachePath;
@end

@implementation czzNotificationBannerViewController
@synthesize statusIcon;
@synthesize dismissButton;
@synthesize headerLabel;
@synthesize parentView;
@synthesize constantHeight;
@synthesize needsToBePresented;
@synthesize currentNotification;
@synthesize notifications;
@synthesize notificationDownloadInterval;
@synthesize updateTextTimer;
@synthesize notificationDownloader;
@synthesize lastUpdateTime;
@synthesize textUpdateInterval;
@synthesize downloadNotificationTimer;
@synthesize cachePath;
@synthesize currentNotificationIndex;
@synthesize notificationManager;
@synthesize homeViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    notificationDownloadInterval = 60 * 60;//every 1 hour
    notifications = [NSMutableOrderedSet new];
    notificationManager = [czzNotificationManager new];
    self.view.layer.shadowOffset = CGSizeMake(4, 4);
    currentNotificationIndex = 0;
    self.view.layer.shadowRadius = 2;
    constantHeight = 44; //the height for this view, should not be changed at all time
    [self updateFrameForVertical];
    textUpdateInterval = 5;
    updateTextTimer = [NSTimer scheduledTimerWithTimeInterval:textUpdateInterval target:self selector:@selector(updateText) userInfo:nil repeats:YES];
    [self checkCachedNotifications];
    //check notification download for the first time
    [self downloadNotification];
    //call every 2 minute, determine if should check for last update time and call for download
    NSTimeInterval notificationDownloaderCheckInterval = 2 * 60;
    downloadNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:notificationDownloaderCheckInterval target:self selector:@selector(downloadNotification) userInfo:nil repeats:YES];
}

#pragma mark - restore cached notification
-(void)checkCachedNotifications {
    NSMutableOrderedSet *cachedSet = [notificationManager checkCachedNotifications];
    if (cachedSet) {
        [notifications addObjectsFromArray:cachedSet.array];
    }
}

#pragma mark - download new notifications from server if criteria met
-(void)downloadNotification {
    //download fresh notifications
    lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastNotificationUpdateTime"];
    
//#if DEBUG
//    lastUpdateTime = nil;
//#endif
    if (!lastUpdateTime || [[NSDate new] timeIntervalSinceDate:lastUpdateTime] > notificationDownloadInterval) {
        notificationDownloader = [czzNotificationDownloader new];
        notificationDownloader.delegate = self;
        [notificationDownloader downloadNotificationWithVendorID:[czzAppDelegate sharedAppDelegate].vendorID];
        lastUpdateTime = [NSDate new];
        [[NSUserDefaults standardUserDefaults] setObject:lastUpdateTime forKey:@"LastNotificationUpdateTime"];
    }

}

#pragma mark - timer selectors
//call every 5 seconds, perfect place to call download methods as well
-(void)updateText {
    if (notifications.count > 0) {
        currentNotification = [notifications objectAtIndex:currentNotificationIndex];
        currentNotificationIndex ++;
        //if exceed the range of this array, move back to the first object
        if (currentNotificationIndex >= notifications.count) {
            currentNotificationIndex = 0;
        }
        [self updateViewsWithCurrentNotification];
    } else {
        self.needsToBePresented = NO;
    }

}

-(void)updateViewsWithCurrentNotification {
    if (currentNotification && currentNotification.timeBeenDisplayed < currentNotification.shouldDisplayXTimes) {
        //current notification has been displayed
        currentNotification.hasDisplayed = YES;
        currentNotification.timeBeenDisplayed += 1;

        statusIcon.hidden = YES;
        if (currentNotification.priority > 1) {
            [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:statusIcon :kCATransitionFade :0.4];
        } else {
            statusIcon.hidden = YES;
        }

        [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:headerLabel :kCATransitionFade :0.4];
        headerLabel.text = currentNotification.title;
        [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:headerLabel :kCATransitionFade :0.4];
    }
}

-(void)setNeedsToBePresented:(BOOL)need {
    needsToBePresented = need;
    if (needsToBePresented) {
        [self updateText];
        [self show];
    } else {
        [self hide];
    }
}

-(void)show {
    //check for all notifications that haven't exceed its own shouldDisplayXTimes property
    if (parentView && !self.view.superview) {
        [parentView addSubview:self.view];
    }
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.view :kCATransitionFromTop :0.2];

}

-(void)hide {
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.view :kCATransitionFromBottom :0.2];
}

- (IBAction)dismissAction:(id)sender {
    self.needsToBePresented = NO;
    for (czzNotification *noti in notifications) {
        noti.timeBeenDisplayed += 1;
    }
    if (currentNotification) {
        currentNotification.timeBeenDisplayed = NSIntegerMax;
    }
    [self saveNotifications];
}

- (IBAction)tapOnViewAction:(id)sender {
    NSLog(@"tap on view");
    if (homeViewController) {
        czzNotificationCentreTableViewController *notificationCentreViewController = [homeViewController.storyboard instantiateViewControllerWithIdentifier:@"notification_centre_view_controller"];
        notificationCentreViewController.currentNotification = currentNotification;
        notificationCentreViewController.notifications = notifications;
        [homeViewController pushViewController:notificationCentreViewController :YES];
        [self setNeedsToBePresented:NO];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //theres an ugly transtition, therefore need to hide it before showing it again
    self.view.hidden = YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [self updateFrameForHorizontal];
    } else {
        [self updateFrameForVertical];
    }
}

-(void)updateFrameForVertical {
    if (parentView) {
        CGRect parentFrame = parentView.bounds;
        CGRect myFrame = self.view.frame;
        myFrame.size.width = parentFrame.size.width;
        myFrame.size.height = constantHeight;
        myFrame.origin.y = parentFrame.size.height - myFrame.size.height;
        self.view.frame = myFrame;
    }
    if (needsToBePresented) {
        [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.view :kCATransitionFromTop :0.2];
    }
}

-(void)updateFrameForHorizontal {
    self.view.hidden = YES;
    if (parentView) {
        CGRect parentFrame = parentView.bounds;
        CGRect myFrame = self.view.frame;
        myFrame.size.width = parentFrame.size.width;
        myFrame.size.height = constantHeight;
        myFrame.origin.y = parentFrame.size.height - myFrame.size.height;
        self.view.frame = myFrame;
    }
    if (needsToBePresented) {
        [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.view :kCATransitionFromTop :0.2];
    }
}

#pragma mark - czzNotificationDownloaderDelegate
-(void)notificationDownloaded:(NSArray *)downloadedNotifications {
#if DEBUG
    [notifications removeAllObjects];
    [notificationManager removeNotifications];
#endif
    NSInteger originalCount = notifications.count;
    if (downloadedNotifications.count > 0) {
        [notifications addObjectsFromArray:downloadedNotifications];
        //if one or more new notifications are downloaded
        if (notifications.count > originalCount) {
            self.needsToBePresented = YES;
            NSArray *sortedArray = [notifications.array sortedArrayUsingComparator: ^(czzNotification* a, czzNotification* b) {
                NSDate *d1 = a.date;
                NSDate *d2 = b.date;
                return [d2 compare: d1];
            }];
            notifications = [NSMutableOrderedSet orderedSetWithArray:sortedArray];
        }
    } else {
        NSLog(@"downloaded notification empty!");
    }
    [self saveNotifications];
}

-(void)saveNotifications {
    if (notifications.count > 0) {
        NSArray *sortedArray = [notifications.array sortedArrayUsingComparator: ^(czzNotification* a, czzNotification* b) {
            NSDate *d1 = a.date;
            NSDate *d2 = b.date;
            return [d2 compare: d1];
        }];
        notifications = [NSMutableOrderedSet orderedSetWithArray:sortedArray];
        [notificationManager saveNotifications:notifications];
    }
}
@end
