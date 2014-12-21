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
#import "czzAppDelegate.h"
#import "czzFeedback.h"
#import "czzSettingsCentre.h"
#import "czzPost.h"
#import "czzPostSender.h"
#import "czzThreadList.h"
#import "PropertyUtil.h"


@interface CustomImageBoardViewerTests : XCTestCase<czzNotificationDownloaderDelegate, czzPostSenderDelegate, czzThreadListProtocol>
@property BOOL done;
@property czzThreadList *threadList;
@end

@implementation CustomImageBoardViewerTests
@synthesize done;
@synthesize threadList;


- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testThreadListDownloadAndLoadMore {
    threadList = [czzThreadList new];
    threadList.delegate = self;
    threadList.forumName = @"日记";
    
    [threadList refresh];
    [self waitForCompletion:20];
    
    XCTAssertTrue(threadList.threads.count > 0);

    [threadList loadMoreThreads];
    [self waitForCompletion:30];

    XCTAssertTrue(threadList.lastBatchOfThreads.count > 0);
    XCTAssertTrue(threadList.threads.count > threadList.lastBatchOfThreads.count);
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
    settingsCentre.userDefShouldCacheData = !settingsCentre.userDefShouldCacheData;
    settingsCentre.userDefShouldDisplayThumbnail = !settingsCentre.userDefShouldDisplayThumbnail;
    settingsCentre.thread_content_host = @"test_thread_content_host";
    XCTAssert([settingsCentre saveSettings], @"failed to save settings!");
    //restore from storage
    czzSettingsCentre *newSettings = [czzSettingsCentre new];
    XCTAssert([newSettings restoreSettings], @"failed to restore settings!");
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
    [downloader downloadNotificationWithVendorID:[czzAppDelegate sharedAppDelegate].vendorID];
    
    XCTAssertTrue([self waitForCompletion:5.0], @"Timeout");

}

-(void)testPostSenderReply {
    return;
    
    czzPostSender *postSender = [czzPostSender new];
    postSender.delegate = self;
    postSender.targetURL = [NSURL URLWithString:@"http://h.acfun.tv/api/t/4010298/create"];
    //content - random bullshit
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"Y-m-d hh-MM-ss"];
    postSender.content = [NSString stringWithFormat:@"TEST - BY IOS AT %@", [dateFormatter stringFromDate:[NSDate new]]];
    NSString *longText = [self generateRandomTextWithLength:1024];
    postSender.content = [postSender.content stringByAppendingString:longText];
    //end content
    postSender.email = @"sage";
    postSender.name = @"渣渣";
    postSender.title = @"渣渣";
    [postSender sendPost];
    XCTAssertTrue([self waitForCompletion:5.0], @"Timeout");
}

-(void)testPostSenderWithImage {
    return;
    
    czzPostSender *postSender = [czzPostSender new];
    postSender.delegate = self;
    postSender.targetURL = [NSURL URLWithString:@"http://h.acfun.tv/api/t/4010298/create"];
    //content - random bullshit
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"Y-m-d hh-MM-ss"];
    postSender.content = [NSString stringWithFormat:@"TEST WITH IMAGE - BY IOS AT %@", [dateFormatter stringFromDate:[NSDate new]]];
    //end content
    postSender.email = @"sage";
    postSender.name = @"渣渣";
    postSender.title = @"渣渣";
    //image
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resource = [bundle pathForResource:@"test_image" ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:resource];
    postSender.imgData = UIImageJPEGRepresentation(img, 0.85);
    //end image
    [postSender sendPost];
    XCTAssertTrue([self waitForCompletion:20.0], @"Timeout");
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
-(void)threadListDownloaded:(czzThreadList *)threadList wasSuccessful:(BOOL)wasSuccessful {
    NSLog(@"thread list downloaded: %@", wasSuccessful ? @"successed" : @"failed");
    XCTAssertTrue(wasSuccessful);
}

-(void)threadListProcessed:(czzThreadList *)threadList wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    NSLog(@"thread list processed");
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
