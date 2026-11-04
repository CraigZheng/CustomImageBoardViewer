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
@synthesize numberButton;
@synthesize homeViewController;

- (void)loadView {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    rootView.backgroundColor = [UIColor whiteColor];
    self.view = rootView;

    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [rootView addSubview:container];

    UIButton *countButton = [UIButton buttonWithType:UIButtonTypeSystem];
    countButton.translatesAutoresizingMaskIntoConstraints = NO;
    countButton.hidden = YES;
    countButton.userInteractionEnabled = NO;
    countButton.backgroundColor = [UIColor colorWithRed:1 green:0.680 blue:0.069 alpha:1];
    countButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [countButton setTitle:@"99" forState:UIControlStateNormal];
    [countButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [container addSubview:countButton];
    self.numberButton = countButton;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"error";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:17];
    [container addSubview:titleLabel];
    self.headerLabel = titleLabel;

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    closeButton.contentMode = UIViewContentModeScaleAspectFit;
    closeButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    [closeButton setImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissAction:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:closeButton];
    self.dismissButton = closeButton;

    [rootView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnViewAction:)]];

    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:rootView.topAnchor],
        [container.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor],
        [container.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [container.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],

        [countButton.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:5],
        [countButton.topAnchor constraintEqualToAnchor:container.topAnchor constant:8],
        [container.bottomAnchor constraintEqualToAnchor:countButton.bottomAnchor constant:8],
        [countButton.widthAnchor constraintEqualToAnchor:countButton.heightAnchor],

        [titleLabel.leadingAnchor constraintEqualToAnchor:countButton.trailingAnchor],
        [titleLabel.topAnchor constraintEqualToAnchor:container.topAnchor],
        [titleLabel.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [closeButton.leadingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],

        [closeButton.topAnchor constraintEqualToAnchor:container.topAnchor],
        [closeButton.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [container.trailingAnchor constraintEqualToAnchor:closeButton.trailingAnchor],
        [closeButton.widthAnchor constraintEqualToAnchor:closeButton.heightAnchor]
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    notificationDownloadInterval = 60 * 60;//every 1 hour
#ifdef DEBUG
    notificationDownloadInterval = 5 * 60;//every 5 minutes for debug
#endif
    notifications = [NSMutableOrderedSet new];
    notificationManager = [czzNotificationManager new];
    self.view.layer.shadowOffset = CGSizeMake(4, 4);
    currentNotificationIndex = 0;
    self.view.layer.shadowRadius = 2;
    constantHeight = 44; //the height for this view, should not be changed at all time
    textUpdateInterval = 5;
    updateTextTimer = [NSTimer scheduledTimerWithTimeInterval:textUpdateInterval target:self selector:@selector(updateText) userInfo:nil repeats:YES];
    [self checkCachedNotifications];
    //check notification download for the first time
    [self downloadNotification];
    //update the number button on the left
    [self updateNumberButton];

    //call every 2 minute, determine if should check for last update time and call for download
    NSTimeInterval notificationDownloaderCheckInterval = 2 * 60;
    downloadNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:notificationDownloaderCheckInterval target:self selector:@selector(downloadNotification) userInfo:nil repeats:YES];
}

#pragma mark - restore cached notification
-(void)checkCachedNotifications {
    NSMutableOrderedSet *cachedSet = [notificationManager checkCachedNotifications];//#ifdef DEBUG
//    needsToBePresented = YES;
//#endif

    if (cachedSet) {
        [notifications addObjectsFromArray:cachedSet.array];
    }
}

#pragma mark - download new notifications from server if criteria met
-(void)downloadNotification {
    //download fresh notifications
    lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastNotificationUpdateTime"];
    
    if (!lastUpdateTime || [[NSDate new] timeIntervalSinceDate:lastUpdateTime] > notificationDownloadInterval) {
        notificationDownloader = [czzNotificationDownloader new];
        notificationDownloader.delegate = self;
        [notificationDownloader downloadNotificationWithVendorID:AppDelegate.vendorID];
        lastUpdateTime = [NSDate new];
        [[NSUserDefaults standardUserDefaults] setObject:lastUpdateTime forKey:@"LastNotificationUpdateTime"];
    }

}

#pragma mark - timer selectors
//call every 5 seconds, perfect place to call download methods as well
-(void)updateText {
    if (notifications.count > 0) {
        @try {
            currentNotification = [notifications objectAtIndex:currentNotificationIndex];
            currentNotificationIndex ++;
            //if exceed the range of this array, move back to the first object
            if (currentNotificationIndex >= notifications.count) {
                currentNotificationIndex = 0;
            }
            [self updateViewsWithCurrentNotification];
        }
        @catch (NSException *exception) {
            DDLogDebug(@"%@", exception);
        }
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
            [AppDelegate doSingleViewShowAnimation:statusIcon :kCATransitionFade :0.4];
        } else {
            statusIcon.hidden = YES;
        }

        [AppDelegate doSingleViewHideAnimation:headerLabel :kCATransitionFade :0.4];
        headerLabel.text = currentNotification.title;
        [AppDelegate doSingleViewShowAnimation:headerLabel :kCATransitionFade :0.4];
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
    [AppDelegate doSingleViewShowAnimation:self.view :kCATransitionFade :0.2];

}

-(void)hide {
    [AppDelegate doSingleViewHideAnimation:self.view :kCATransitionFade :0.2];
}

- (IBAction)dismissAction:(id)sender {
    self.needsToBePresented = NO;
    for (czzNotification *noti in notifications) {
        noti.timeBeenDisplayed += 3;
    }
    if (currentNotification) {
        currentNotification.timeBeenDisplayed = NSIntegerMax;
    }
    [self saveNotifications];
}

- (IBAction)tapOnViewAction:(id)sender {
    DDLogDebug(@"tap on view");
    if (homeViewController) {
        czzNotificationCentreTableViewController *notificationCentreViewController = [czzNotificationCentreTableViewController new];
        notificationCentreViewController.currentNotification = currentNotification;
        notificationCentreViewController.notifications = notifications;
        
        [homeViewController pushViewController:notificationCentreViewController animated:YES];
        [self dismissAction:nil];
    }
}

-(BOOL)shouldShow {
    return needsToBePresented;
}

-(void)updateNumberButton {
    numberButton.layer.cornerRadius = numberButton.frame.size.width / 2;
    if (notifications.count > 1) {
        [numberButton setTitle:[NSString stringWithFormat:@"%ld", (long) notifications.count] forState:UIControlStateNormal];
        numberButton.hidden = NO;
    } else
        numberButton.hidden = YES;
}

#pragma mark - czzNotificationDownloaderDelegate
-(void)notificationDownloaded:(NSArray *)downloadedNotifications {
//#ifdef DEBUG
//    [notifications removeAllObjects];
//    [notificationManager removeNotifications];
//#endif
    NSInteger originalCount = notifications.count;
    if (downloadedNotifications.count > 0) {
        [notifications removeAllObjects]; //remove all and accept whats been downloaded
        [notifications addObjectsFromArray:downloadedNotifications];
        //if one or more new notifications are downloaded
        if (notifications.count != originalCount) {
            self.needsToBePresented = YES;
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
    } else {
        DDLogDebug(@"downloaded notification empty!");
    }
    [self saveNotifications];
}

-(void)saveNotifications {
    if (notifications.count > 0) {
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
        [notificationManager saveNotifications:notifications];
    }
}
@end
