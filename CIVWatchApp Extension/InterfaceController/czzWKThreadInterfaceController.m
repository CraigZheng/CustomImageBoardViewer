//
//  czzWKThreadInterfaceController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWKThreadInterfaceController.h"

#import "czzWatchKitCommand.h"
#import "czzWatchKitHomeRowController.h"
#import "ExtensionDelegate.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface czzWKThreadInterfaceController () <czzWKSessionDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *idLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkThreadsTableView;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *moreButton;
@property (strong, nonatomic) NSMutableArray *wkThreads;
@property (assign, nonatomic) NSInteger pageNumber;
@end

@implementation czzWKThreadInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.parentWKThread = [[czzWKThread alloc] initWithDictionary:[context objectForKey:@(watchKitCommandLoadThreadView)]];
    self.pageNumber = 1;
}

- (IBAction)loadMoreButtonAction {
    [self loadMore];
}

- (IBAction)watchButtonAction {
    if (self.parentWKThread) {
#warning TODO: MADE IT COMPATIBLE WITH WATCH OS 2
//        [WKInterfaceController openParentApplication:@{@(watchKitCommandWatchThread) : [self.wkThread encodeToDictionary]} reply:^(NSDictionary * replyInfo, NSError * error) {
//            
//        }];
    }
}

#pragma mark - Life cycle.
- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    if (!self.wkThreads.count) {
        [self loadMore];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(void)loadMore {
    if (self.parentWKThread) {
        // Disable the load more button until a response is received.
        [self.moreButton setEnabled:NO];
        czzWatchKitCommand *loadCommand = [czzWatchKitCommand new];
        loadCommand.caller = NSStringFromClass(self.class);
        loadCommand.action = watchKitCommandLoadThreadView;
        loadCommand.parameter = @{@"THREAD" : self.parentWKThread.encodeToDictionary,
                                  @"PAGE" : @(self.pageNumber)};
        [[ExtensionDelegate sharedInstance] sendCommand:loadCommand withCaller:self];
#warning TODO: MADE IT COMPATIBLE WITH WATCH OS 2
//        [WKInterfaceController openParentApplication:@{watchKitCommandKey : @(watchKitCommandLoadThreadView),
//                                                       @"THREAD" : [self.wkThread encodeToDictionary],
//                                                       watchKitCommandLoadMore : @(YES)} reply:^(NSDictionary *replyInfo, NSError * error) {
//            self.wkThreads = [NSMutableArray new];
//            for (NSDictionary *dict in [replyInfo objectForKey:@(watchKitCommandLoadThreadView)]) {
//                czzWKThread *thread = [[czzWKThread alloc] initWithDictionary:dict];
//                [self.wkThreads addObject:thread];
//            }
//            [self reloadTableView];
//        }];
//        [self.idLabel setText:[NSString stringWithFormat:@"No. %ld", (long)self.wkThread.ID]];
    }
}

#pragma mark - czzWKSessionDelegate

- (void)respondReceived:(NSDictionary *)response error:(NSError *)error {
    // Re-enable the more button.
    [self.moreButton setEnabled:YES];
    if (response.count) {
        self.pageNumber ++;
        NSArray *jsonThreads = [response objectForKey:NSStringFromClass(self.class)];
        for (NSDictionary *jsonDict in jsonThreads) {
            czzWKThread *wkThread = [[czzWKThread alloc] initWithDictionary:jsonDict];
            [self.wkThreads addObject:wkThread];
        }
    }
    [self reloadTableView];
}

#pragma mark - Getter

- (NSMutableArray *)wkThreads {
    if (!_wkThreads) {
        _wkThreads = [NSMutableArray new];
        [_wkThreads addObject:self.parentWKThread];
    }
    return _wkThreads;
}

#pragma mark - TableView

-(void)reloadTableView {
    [self.wkThreadsTableView setNumberOfRows:self.wkThreads.count withRowType:wkHomeViewRowControllerIdentifier];
    
    [self.wkThreads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        czzWatchKitHomeRowController* theRow = [self.wkThreadsTableView rowControllerAtIndex:idx];
        
        theRow.wkThread = obj;
    }];
    
}

@end



