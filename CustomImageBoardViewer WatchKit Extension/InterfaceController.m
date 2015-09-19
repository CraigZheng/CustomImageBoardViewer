//
//  InterfaceController.m
//  CustomImageBoardViewer WatchKit Extension
//
//  Created by Craig on 9/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "InterfaceController.h"
#import "czzWKThread.h"
#import "czzWatchKitCommand.h"
#import "czzWatchKitHomeRowController.h"

@interface InterfaceController()

@property (strong, nonatomic) NSMutableArray *wkThreads;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [WKInterfaceController openParentApplication:@{@"COMMAND" : @(watchKitCommandLoadHomeView)} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"MAIN APP CALLED COMPLETION HANDLER");
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

- (void)willActivate {
    [super willActivate];
    [self reloadTableView];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
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



