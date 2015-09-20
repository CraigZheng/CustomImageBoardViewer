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
#import "czzWKThreadViewController.h"

@interface InterfaceController()

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
    [WKInterfaceController openParentApplication:@{watchKitCommandKey : @(watchKitCommandLoadHomeView), watchKitCommandLoadMore : @(more),
                                                   watchKitCommandForumKey : [self.selectedForum encodeToDictionary]} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSArray *threadDictionaries = [replyInfo objectForKey:@(watchKitCommandLoadHomeView)];
        self.wkThreads = [NSMutableArray new];
        for (NSDictionary *dict in threadDictionaries) {
            czzWKThread *thread = [[czzWKThread alloc] initWithDictionary:dict];
            NSLog(@"thread: %@", thread);
            [self.wkThreads addObject:thread];
        }
        [self.screenTitleLabel setText:[replyInfo objectForKey:@(watchKitMiscInfoScreenTitleHome)]];
        
        [self reloadTableView];
    }];
}

- (IBAction)reloadButtonAction {
    [self reloadData];
}

- (IBAction)loadMoreButtonAction {
    [self loadMore:YES];
}


-(id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    self.selectedThread = [self.wkThreads objectAtIndex:rowIndex];
    
    return @{@(watchKitCommandLoadThreadView) : [self.selectedThread encodeToDictionary]};
}

#pragma mark - TableView
-(void)reloadTableView {
    [self.wkThreadsTableView setNumberOfRows:self.wkThreads.count withRowType:wkHomeViewRowControllerIdentifier];
    
    [self.wkThreads enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        czzWatchKitHomeRowController* theRow = [self.wkThreadsTableView rowControllerAtIndex:idx];
        
        theRow.wkThread = obj;
    }];

}

@end



