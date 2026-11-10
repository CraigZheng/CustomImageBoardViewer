//
//  CustomImageBoardViewerTests.m
//  CustomImageBoardViewerTests
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "czzNotification.h"
#import "czzNotificationDownloader.h"
#import "SMXMLDocument.h"
#import "czzFeedback.h"
#import "czzSettingsCentre.h"
#import "czzPost.h"
#import "czzPostSender.h"
#import "czzHomeViewManager.h"
#import "czzThreadViewManager.h"
#import "czzHistoryManager.h"
#import "PropertyUtil.h"


@interface CustomImageBoardViewerTests : XCTestCase<czzNotificationDownloaderDelegate, czzPostSenderDelegate, czzHomeViewManagerDelegate>
@property (assign, nonatomic) BOOL done;
@end

@implementation CustomImageBoardViewerTests
@synthesize done;

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testHistoryManager {
    czzThread *thread = [czzThread new];
    thread.ID = 5361014;
    thread.content = [[NSAttributedString alloc] initWithString:NSStringFromSelector(_cmd) attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}];
    [historyManager clearRecord];
    [historyManager recordThread:thread];
    XCTAssert([historyManager browserHistory].count > 0);
    
    //adding same thread
    czzThread *thread2 = [czzThread new];
    thread2.ID = 5361014;
    thread2.content = [[NSAttributedString alloc] initWithString:NSStringFromSelector(_cmd) attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}];
    [historyManager recordThread:thread2];

    XCTAssert([historyManager browserHistory].count == 1);

    //adding different thread
    czzThread* thread3 = [czzThread new];
    thread3.ID = 239857019;
    thread3.content = [[NSAttributedString alloc] initWithString:@"dfgajnlgakml" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}];

    [historyManager recordThread:thread3];
    XCTAssert([historyManager browserHistory].count == 2);
    
    //test saving and restoring sate
    [historyManager saveCurrentState];
    NSMutableOrderedSet *set = [[czzHistoryManager new] browserHistory];
    XCTAssert(set.count != 0);
    
    //test clearing state
    [historyManager clearRecord];
    set = [[czzHistoryManager new] browserHistory];
    XCTAssert(set.count == 0);

}

-(void)testRecordedPageNumber {
    czzThread *thread = [czzThread new];
    thread.ID = 424242;
    czzThreadViewManager *viewManager = [[czzThreadViewManager alloc] initWithParentThread:thread andForum:nil];

    // A never-visited thread starts on page 1 rather than page 0.
    [viewManager restorePreviousState];
    XCTAssertEqual(viewManager.pageNumber, 1);

    // The saved page is the one being read, which is not always the furthest loaded.
    viewManager.pageNumber = 7;
    [viewManager saveCurrentState];
    czzThreadViewManager *reopened = [[czzThreadViewManager alloc] initWithParentThread:thread andForum:nil];
    [reopened restorePreviousState];
    XCTAssertEqual(reopened.pageNumber, 7);

    // Recording is bounded: exceeding the cap drops the oldest entries.
    for (NSInteger threadID = 0; threadID < 250; threadID++) {
        czzThread *extraThread = [czzThread new];
        extraThread.ID = 500000 + threadID;
        czzThreadViewManager *extraManager = [[czzThreadViewManager alloc] initWithParentThread:extraThread andForum:nil];
        extraManager.pageNumber = 2;
        [extraManager saveCurrentState];
    }
    NSInteger recordedCount = 0;
    for (NSString *key in [NSUserDefaults standardUserDefaults].dictionaryRepresentation.allKeys) {
        if ([key hasPrefix:@"czzRecordedPageNumber."]) {
            recordedCount++;
        }
    }
    XCTAssertLessThanOrEqual(recordedCount, 200);
}

-(void)testLegacyRecordedPageNumberMigration {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *host = [czzSettingsCentre sharedInstance].activeHost;
    XCTAssertTrue(host.length > 0, @"need an active host to build a legacy key");

    // Reproduce the pre-namespace format: "<host><threadID>" holding a bare integer.
    czzThread *thread = [czzThread new];
    thread.ID = 313131;
    NSString *legacyKey = [host stringByAppendingFormat:@"%ld", (long)thread.ID];
    NSString *migratedKey = [NSString stringWithFormat:@"czzRecordedPageNumber.%@|%ld", host, (long)thread.ID];
    [userDefault setInteger:9 forKey:legacyKey];
    [userDefault removeObjectForKey:@"czzRecordedPageNumberMigrated"];

    czzThreadViewManager *viewManager = [[czzThreadViewManager alloc] initWithParentThread:thread andForum:nil];
    [viewManager restorePreviousState];

    XCTAssertEqual(viewManager.pageNumber, 9, @"legacy page number should survive the migration");
    XCTAssertNil([userDefault objectForKey:legacyKey], @"legacy key should be dropped");
    XCTAssertNotNil([userDefault objectForKey:migratedKey]);
}

-(void)testSettingsCentre {
    czzSettingsCentre *settingsCentre = [czzSettingsCentre sharedInstance];
    XCTAssertEqual(3600, settingsCentre.configuration_refresh_interval, "configuration not equal to 3600!");
//    [settingsCentre downloadSettings];
//    [self waitForCompletion:5];
    settingsCentre.shouldHideImageInForums = @[@"1", @"2", @"3", @"4"];
    settingsCentre.shouldDisplayContent = !settingsCentre.shouldDisplayContent;
    settingsCentre.ac_host = @"test_ac_host";
    settingsCentre.userDefShouldAutoOpenImage = !settingsCentre.userDefShouldAutoOpenImage;
    settingsCentre.userDefShouldHighlightPO = !settingsCentre.userDefShouldHighlightPO;
    settingsCentre.userDefShouldDisplayThumbnail = !settingsCentre.userDefShouldDisplayThumbnail;
    settingsCentre.thread_content_host = @"test_thread_content_host";
    [settingsCentre saveSettings];
    //restore from storage
    czzSettingsCentre *newSettings = [czzSettingsCentre new];
    [newSettings restoreSettings];
    //test every property
    NSArray *properties = [PropertyUtil classPropsFor:settingsCentre.class].allKeys;
    for (NSString *property in properties) {
        NSObject *obj1 = [settingsCentre valueForKey:property];
        NSObject *obj2 = [newSettings valueForKey:property];
        XCTAssertEqualObjects(obj1, obj2, @"%@ not equal!", property);
    }
}

- (void)testFeedback {
    czzFeedback *feedback = [czzFeedback new];
    czzNotification *notification = [czzNotification new];
    notification.notificationID = @"IOS TEST notification ID";
    feedback.name = @"IOS TEST";
    feedback.title = @"IOS TEST";
    feedback.content = @"IOS TEST";
    XCTAssertTrue(    [feedback sendFeedback:notification], @"failed to send feedback!");
    
}

- (void)testNotification
{
    NSError *error;
    NSString *xmlString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://civ.atwebpages.com/test.xml"] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"error %@", error);
    }
    SMXMLDocument *xmlDoc = [SMXMLDocument documentWithData:[xmlString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    czzNotification *notification;
    for (SMXMLElement *element in xmlDoc.root.children) {
        if ([element.name isEqualToString:@"message"]) {
            notification = [[czzNotification alloc] initWithXMLElement:element];
        }
    }
    
    XCTAssertNotNil(notification, @"notification not initialised");
    XCTAssertNotEqual(notification.sender, [czzNotification new].sender, @"sender has not set!");
}

- (void)testNotificationDownloader {
    done = NO;
    czzNotificationDownloader *downloader = [czzNotificationDownloader new];
    downloader.delegate = self;
    [downloader downloadNotificationWithVendorID:AppDelegate.vendorID];
    
    XCTAssertTrue([self waitForCompletion:5.0], @"Timeout");

}

-(NSString*)generateRandomTextWithLength:(NSInteger)length {
    NSString *candidates = @"abcdefghijklmnoprrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *string = [NSMutableString new];
    for (NSInteger i = 0; i < length; i++) {
        NSInteger index = arc4random() % candidates.length;
        [string appendString:[candidates substringWithRange:NSMakeRange(index, 1)]];
    }
    return string;
}

#pragma mark - czzNotificationDownloaderDelegate 
-(void)notificationDownloaded:(NSArray *)notifications {
    done = YES;
    XCTAssertTrue(notifications.count > 0, @"downloaded notification list empty!");
}

#pragma mark - czzPostSenderDelegate
-(void)statusReceived:(BOOL)status message:(NSString *)message {
    NSLog(@"message: %@", message);
    XCTAssertTrue(status, @"status not YES");
    done = YES;
}

#pragma mark - czzThreadListProtocol 
-(void)homeViewManager:(czzHomeViewManager *)threadList downloadSuccessful:(BOOL)wasSuccessful {
    NSLog(@"thread list downloaded: %@", wasSuccessful ? @"successed" : @"failed");
    XCTAssertTrue(wasSuccessful);
}

-(void)homeViewManager:(czzHomeViewManager *)threadList threadListProcessed:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    NSLog(@"thread list processed");
    done = YES;
}

-(void)homeViewManager:(czzHomeViewManager *)threadList threadContentProcessed:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    DLog(@"%@", NSStringFromSelector(_cmd));
    XCTAssertTrue(wasSuccessul);
    done = YES;
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!done);
    
    return done;
}
@end
