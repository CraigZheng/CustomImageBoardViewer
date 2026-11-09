//
//  VerifyMenuOpenLink.m
//  The 打开链接 menu used to build a UIActionSheet that silently never appeared
//  on iOS 26, and on-site links were never recognised because the comparison
//  used a full URL prefix against an https link. Both are covered here.
//

#import <XCTest/XCTest.h>
#import "czzMenuEnabledTableViewCell.h"
#import "czzThread.h"
#import "czzSettingsCentre.h"
#import "UIApplication+Util.h"

@interface VerifyMenuOpenLink : XCTestCase <czzMenuEnabledTableViewCellProtocol>
@property (nonatomic, strong) NSString *quotedTextPassed;
@end

@implementation VerifyMenuOpenLink

- (void)userTapInQuotedText:(NSString *)text { self.quotedTextPassed = text; }
- (void)userTapInImageView:(id)sender {}
- (void)threadViewCellContentChanged:(czzMenuEnabledTableViewCell *)cell {}

- (czzMenuEnabledTableViewCell *)cell {
    czzThread *thread = [czzThread new];
    thread.ID = 1;
    thread.content = [[NSAttributedString alloc] initWithString:@"see https://example.com/page and https://www.nmbxd1.com/t/999"];
    czzMenuEnabledTableViewCell *cell = [czzMenuEnabledTableViewCell threadCell];
    cell.thread = thread;
    cell.delegate = self;
    return cell;
}

- (void)testLinkPickerBuildsAnActionForEachLink {
    czzMenuEnabledTableViewCell *cell = [self cell];
    UIAlertController *picker = [cell linkPicker];
    NSLog(@"VERIFY picker actions=%lu titles=%@",
          (unsigned long)picker.actions.count,
          [picker.actions valueForKey:@"title"]);
    // Two links plus a cancel button.
    XCTAssertEqual(picker.actions.count, 3);
    XCTAssertEqualObjects(picker.actions.firstObject.title, @"https://example.com/page");
    XCTAssertEqualObjects(picker.actions[1].title, @"https://www.nmbxd1.com/t/999");
    XCTAssertEqualObjects(picker.actions.lastObject.title, @"取消");
    XCTAssertEqual(picker.preferredStyle, UIAlertControllerStyleActionSheet);
}

- (void)testMenuActionOpenFindsAHost {
    [self cell]; // warm the singleton lookups
    UIViewController *host = [UIApplication topViewController];
    NSLog(@"VERIFY topViewController=%@", host);
    XCTAssertNotNil(host, @"menuActionOpen needs a host to present on");
}

- (void)testOffSiteLinkOpensThroughTheSystem {
    czzMenuEnabledTableViewCell *cell = [self cell];
    self.quotedTextPassed = nil;
    [cell openLink:@"https://example.com/page"];
    XCTAssertNil(self.quotedTextPassed, @"off-site links must not be routed as quoted threads");
}

- (void)testOnSiteLinkRoutesAsQuotedThread {
    czzMenuEnabledTableViewCell *cell = [self cell];
    self.quotedTextPassed = nil;
    [cell openLink:@"https://www.nmbxd1.com/t/999"];
    XCTAssertEqualObjects(self.quotedTextPassed, @"/t/999",
                          @"on-site links must be handed to the delegate as a thread path");
}

- (void)testOnSiteLinkRoutesAcrossSchemeMismatch {
    czzMenuEnabledTableViewCell *cell = [self cell];
    self.quotedTextPassed = nil;
    // The active host is http; thread content carries https. Both must route.
    [cell openLink:@"http://www.nmbxd1.com/t/888"];
    XCTAssertEqualObjects(self.quotedTextPassed, @"/t/888");
}

@end
