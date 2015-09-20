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

@interface czzWKThreadViewController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *idLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkThreadsTableView;
@property (strong, nonatomic) NSMutableArray *wkThreads;

@end

@implementation czzWKThreadViewController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.wkThread = [[czzWKThread alloc] initWithDictionary:[context objectForKey:@(watchKitCommandLoadThreadView)]];
    if (self.wkThread) {
        [WKInterfaceController openParentApplication:@{@"COMMAND" : @(watchKitCommandLoadThreadView), @"THREAD" : [self.wkThread encodeToDictionary]} reply:^(NSDictionary * _Nonnull replyInfo, NSError * _Nullable error) {
            
        }];
        [self.idLabel setText:[NSString stringWithFormat:@"No. %ld - ID %@", (long)self.wkThread.ID, self.wkThread.name]];
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

#pragma mark - TableView
-(void)reloadData {
    [WKInterfaceController openParentApplication:@{@"COMMAND" : @(watchKitCommandLoadHomeView)} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"MAIN APP CALLED COMPLETION HANDLER");
        NSArray *threadDictionaries = [replyInfo objectForKey:@(watchKitCommandLoadHomeView)];
        self.wkThreads = [NSMutableArray new];
        for (NSDictionary *dict in threadDictionaries) {
            czzWKThread *thread = [[czzWKThread alloc] initWithDictionary:dict];
            NSLog(@"thread: %@", thread);
            [self.wkThreads addObject:thread];
        }
        [self.idLabel setText:[replyInfo objectForKey:@(watchKitMiscInfoScreenTitleHome)]];
        
        [self reloadTableView];
    }];
}
-(void)reloadTableView {
    [self.wkThreadsTableView setNumberOfRows:self.wkThreads.count withRowType:wkHomeViewRowControllerIdentifier];
    
    [self.wkThreads enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        czzWatchKitHomeRowController* theRow = [self.wkThreadsTableView rowControllerAtIndex:idx];
        
        theRow.wkThread = obj;
    }];
    
}

@end



