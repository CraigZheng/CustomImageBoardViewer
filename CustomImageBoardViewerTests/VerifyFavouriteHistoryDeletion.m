//
//  VerifyFavouriteHistoryDeletion.m
//  Regression tests for history/favourites deletion and configuration parsing.
//

#import <XCTest/XCTest.h>
#import "czzFavouriteManager.h"
#import "czzHistoryManager.h"
#import "czzFavouriteManagerViewController.h"
#import "czzThreadTableView.h"
#import "czzThread.h"
#import "czzSettingsCentre.h"

@interface czzFavouriteManagerViewController (Testing)
- (void)copyDataFromManager;
@end

@interface czzSettingsCentre (Testing)
- (void)setConfigurationJSONData:(NSData *)data;
@end

@interface VerifyFavouriteHistoryDeletion : XCTestCase
@property (nonatomic, strong) NSString *savedActiveHost;
@property (nonatomic, strong) NSString *savedAcHost;
@property (nonatomic, strong) NSString *savedImageHost;
@end

@implementation VerifyFavouriteHistoryDeletion

- (void)setUp {
    [super setUp];
    // The history manager is a singleton, so start every case from a clean slate.
    [historyManager.browserHistory removeAllObjects];
    [historyManager.postedThreads removeAllObjects];
    [historyManager.respondedThreads removeAllObjects];
    [favouriteManager.favouriteThreads removeAllObjects];
    // Settings are global too; other suites compare links against activeHost.
    self.savedActiveHost = settingCentre.activeHost;
    self.savedAcHost = settingCentre.ac_host;
    self.savedImageHost = settingCentre.image_host;
}

- (void)tearDown {
    settingCentre.activeHost = self.savedActiveHost;
    settingCentre.ac_host = self.savedAcHost;
    settingCentre.image_host = self.savedImageHost;
    [super tearDown];
}

- (czzThread *)threadWithID:(NSInteger)threadID uid:(NSString *)uid {
    czzThread *thread = [czzThread new];
    thread.ID = threadID;
    thread.UID = uid;
    thread.content = [[NSAttributedString alloc] initWithString:@"content"];
    return thread;
}

- (czzFavouriteManagerViewController *)presentedController {
    czzFavouriteManagerViewController *vc = [czzFavouriteManagerViewController new];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 393, 852)];
    window.rootViewController = vc;
    [window makeKeyAndVisible];
    [vc viewDidLoad];
    [vc.view layoutIfNeeded];
    return vc;
}

#pragma mark - History deletion scope

- (void)testDeletingBrowserEntryLeavesPostedAndRespondedIntact {
    czzThread *thread = [self threadWithID:770001 uid:@"SCOPE1"];
    [historyManager recordThread:thread];
    [historyManager addToPostedList:thread];
    [historyManager addToRespondedList:thread];

    XCTAssertTrue([historyManager removeThread:thread fromList:czzHistoryListTypeBrowser]);

    XCTAssertFalse([historyManager.browserHistory containsObject:thread],
                   @"the deleted browser entry should be gone");
    XCTAssertTrue([historyManager.postedThreads containsObject:thread],
                  @"the sent record must survive deleting the browser entry");
    XCTAssertTrue([historyManager.respondedThreads containsObject:thread],
                  @"the replied record must survive deleting the browser entry");
}

- (void)testDeletingPostedEntryLeavesBrowserIntact {
    czzThread *thread = [self threadWithID:770002 uid:@"SCOPE2"];
    [historyManager recordThread:thread];
    [historyManager addToPostedList:thread];

    XCTAssertTrue([historyManager removeThread:thread fromList:czzHistoryListTypePosted]);
    XCTAssertTrue([historyManager.browserHistory containsObject:thread]);
    XCTAssertFalse([historyManager.postedThreads containsObject:thread]);
}

- (void)testDeletingMissingEntryReportsNoChange {
    czzThread *thread = [self threadWithID:770003 uid:@"SCOPE3"];
    XCTAssertFalse([historyManager removeThread:thread fromList:czzHistoryListTypeResponded]);
}

#pragma mark - Controller wiring

- (void)testControllerDeletesOnlyFromTheVisibleHistoryList {
    czzFavouriteManagerViewController *vc = [self presentedController];
    czzThread *thread = [self threadWithID:770004 uid:@"SCOPE4"];
    [historyManager recordThread:thread];
    [historyManager addToPostedList:thread];

    // Show 浏览 (browser) and delete the row through the table path the UI uses.
    vc.titleSegmentedControl.selectedSegmentIndex = historyIndex;
    vc.historyTypeSegmentedControl.selectedSegmentIndex = 0; // 浏览
    [vc copyDataFromManager];

    NSInteger row = [vc.threads indexOfObject:thread];
    XCTAssertNotEqual(row, (NSInteger)NSNotFound, @"thread should be listed under 浏览");

    [vc tableView:vc.tableView
        commitEditingStyle:UITableViewCellEditingStyleDelete
     forRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];

    XCTAssertFalse([historyManager.browserHistory containsObject:thread],
                   @"deleting from 浏览 removes the browser entry");
    XCTAssertTrue([historyManager.postedThreads containsObject:thread],
                  @"deleting from 浏览 must not touch the 发送 list");
}

- (void)testDeletingFromSentTabRemovesOnlySentEntry {
    czzFavouriteManagerViewController *vc = [self presentedController];
    czzThread *thread = [self threadWithID:770005 uid:@"SCOPE5"];
    [historyManager recordThread:thread];
    [historyManager addToPostedList:thread];

    vc.titleSegmentedControl.selectedSegmentIndex = historyIndex;
    vc.historyTypeSegmentedControl.selectedSegmentIndex = 1; // 发送
    [vc copyDataFromManager];

    NSInteger row = [vc.threads indexOfObject:thread];
    XCTAssertNotEqual(row, (NSInteger)NSNotFound);

    [vc tableView:vc.tableView
        commitEditingStyle:UITableViewCellEditingStyleDelete
     forRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];

    XCTAssertFalse([historyManager.postedThreads containsObject:thread]);
    XCTAssertTrue([historyManager.browserHistory containsObject:thread],
                  @"the 浏览 entry must survive deleting from 发送");
}

#pragma mark - Bounds safety

- (void)testDeletingOutOfRangeRowDoesNotRaise {
    czzFavouriteManagerViewController *vc = [self presentedController];
    vc.titleSegmentedControl.selectedSegmentIndex = bookmarkIndex;
    [vc copyDataFromManager];

    XCTAssertNoThrow([vc tableView:vc.tableView
               commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:9999 inSection:0]]);
}

#pragma mark - Configuration parsing

- (void)testMalformedConfigurationIsIgnored {
    czzSettingsCentre *s = settingCentre;
    NSString *hostBefore = s.ac_host;

    // A dictionary (the shape older server scripts return) must not raise.
    NSData *dictForm = [NSJSONSerialization dataWithJSONObject:@{@"ac_host": @"https://should-not-apply"}
                                                       options:0 error:nil];
    XCTAssertNoThrow([s setConfigurationJSONData:dictForm]);
    XCTAssertEqualObjects(s.ac_host, hostBefore, @"a non-array config must not be applied");

    NSData *garbage = [@"not json" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNoThrow([s setConfigurationJSONData:garbage]);
    XCTAssertEqualObjects(s.ac_host, hostBefore);
}

- (void)testSparseConfigurationKeepsExistingEndpoints {
    czzSettingsCentre *s = settingCentre;
    NSString *hostBefore = s.ac_host;
    NSString *imageBefore = s.image_host;

    NSData *sparse = [NSJSONSerialization dataWithJSONObject:@[
        @{@"configuration_name": @"AC", @"a_isle_host": @"https://config.example"}
    ] options:0 error:nil];
    [s setConfigurationJSONData:sparse];

    XCTAssertEqualObjects(s.ac_host, hostBefore,
                          @"an omitted key must not nil out the existing endpoint");
    XCTAssertEqualObjects(s.image_host, imageBefore,
                          @"an omitted key must not nil out the existing endpoint");
}

- (void)testPresentConfigurationKeysStillApply {
    czzSettingsCentre *s = settingCentre;
    NSString *hostBefore = s.ac_host;

    NSData *config = [NSJSONSerialization dataWithJSONObject:@[
        @{@"configuration_name": @"AC",
          @"a_isle_host": @"https://config.example",
          @"ac_host": hostBefore}
    ] options:0 error:nil];
    [s setConfigurationJSONData:config];

    XCTAssertEqualObjects(s.ac_host, hostBefore);
    XCTAssertEqualObjects(settingCentre.activeHost, @"https://config.example",
                          @"a key that is present should still be applied");
}

@end
