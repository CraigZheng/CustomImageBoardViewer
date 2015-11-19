//
//  czzWKThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWKThreadViewController.h"

#import "czzWatchKitCommand.h"
#import "czzWatchKitHomeRowController.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface czzWKThreadViewController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *idLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkThreadsTableView;
@property (strong, nonatomic) NSMutableArray *wkThreads;

@end

@implementation czzWKThreadViewController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.wkThread = [[czzWKThread alloc] initWithDictionary:[context objectForKey:@(watchKitCommandLoadThreadView)]];
    [self loadMore];
}

- (IBAction)loadMoreButtonAction {
    [self loadMore];
}

- (IBAction)watchButtonAction {
    if (self.wkThread) {
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
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(void)loadMore {
    if (self.wkThread) {
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

#pragma mark - TableView

-(void)reloadTableView {
    [self.wkThreadsTableView setNumberOfRows:self.wkThreads.count withRowType:wkHomeViewRowControllerIdentifier];
    
    [self.wkThreads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        czzWatchKitHomeRowController* theRow = [self.wkThreadsTableView rowControllerAtIndex:idx];
        
        theRow.wkThread = obj;
    }];
    
}

@end



