//
//  InterfaceController.m
//  CustomImageBoardViewer WatchKit Extension
//
//  Created by Craig on 9/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "InterfaceController.h"
#import "czzWKThread.h"
#import "czzWKForum.h"
#import "czzWatchKitCommand.h"
#import "czzWatchKitHomeRowController.h"
#import "czzWKThreadInterfaceController.h"
#import "ExtensionDelegate.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController() <czzWKSessionDelegate>

@property (strong, nonatomic) NSMutableArray *wkThreads;
@property (strong, nonatomic) czzWKForum *selectedForum;
@property (strong, nonatomic) czzWKThread *selectedThread;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.selectedForum = [[czzWKForum alloc] initWithDictionary:[context objectForKey:@(watchKitCommandLoadForumView)]];
    
}

- (void)willActivate {
    [super willActivate];
    if (!self.wkThreads.count) {
        [self reloadData];
    }
    [self reloadTableView];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(void)reloadData {
    [self loadMore:NO];
}

-(void)loadMore:(BOOL)more {
    czzWatchKitCommand *loadCommand = [czzWatchKitCommand new];
    loadCommand.caller = NSStringFromClass(self.class);
    loadCommand.action = watchKitCommandLoadHomeView;
    loadCommand.parameter = @{@"FORUM" : self.selectedForum.encodeToDictionary,
                              @"PAGE" : @(1)};
    [[ExtensionDelegate sharedInstance] sendCommand:loadCommand
                                         withCaller:self];
//    [WKInterfaceController openParentApplication:@{watchKitCommandKey : @(watchKitCommandLoadHomeView), watchKitCommandLoadMore : @(more),
//                                                   watchKitCommandForumKey : [self.selectedForum encodeToDictionary]} reply:^(NSDictionary *replyInfo, NSError *error) {
//        NSArray *threadDictionaries = [replyInfo objectForKey:@(watchKitCommandLoadHomeView)];
//        self.wkThreads = [NSMutableArray new];
//        for (NSDictionary *dict in threadDictionaries) {
//            czzWKThread *thread = [[czzWKThread alloc] initWithDictionary:dict];
//            NSLog(@"thread: %@", thread);
//            [self.wkThreads addObject:thread];
//        }
//        [self.screenTitleLabel setText:[replyInfo objectForKey:@(watchKitMiscInfoScreenTitleHome)]];
//        
//        [self reloadTableView];
//    }];
}

- (IBAction)reloadButtonAction {
    [self reloadData];
}

- (IBAction)loadMoreButtonAction {
    [self loadMore:YES];
}

#pragma mark - czzWKSessionDelegate
- (void)respondReceived:(NSDictionary *)response error:(NSError *)error {
    DLog(@"%s : %@ : %@", __PRETTY_FUNCTION__, response, error);
}

#pragma mark - segue
-(id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    self.selectedThread = [self.wkThreads objectAtIndex:rowIndex];
    
    return @{@(watchKitCommandLoadThreadView) : [self.selectedThread encodeToDictionary]};
}

#pragma mark - WCSessionDelegate
-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    
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



