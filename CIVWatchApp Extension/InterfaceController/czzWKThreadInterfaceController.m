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
#import "WKInterfaceImage+ActivityIndicator.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface czzWKThreadInterfaceController () <czzWKSessionDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *idLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkThreadsTableView;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *moreButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *loadingIndicator;
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
        czzWatchKitCommand *watchCommand = [czzWatchKitCommand new];
        watchCommand.caller = NSStringFromClass(self.class);
        watchCommand.action = watchKitCommandWatchThread;
        watchCommand.parameter = @{@"THREAD" : self.parentWKThread.encodeToDictionary};
        [[ExtensionDelegate sharedInstance] sendCommand:watchCommand withCaller:self];
    }
}

#pragma mark - Life cycle.
- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    // self.wkThreads will always include a parent thread.
    if (self.wkThreads.count <= 1) {
        [self loadMore];
    } else {
        [self reloadTableView];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(void)loadMore {
    if (self.parentWKThread) {
        [self.loadingIndicator startLoading];
        
        // Disable the load more button until a response is received.
        [self.moreButton setEnabled:NO];
        czzWatchKitCommand *loadCommand = [czzWatchKitCommand new];
        loadCommand.caller = NSStringFromClass(self.class);
        loadCommand.action = watchKitCommandLoadThreadView;
        loadCommand.parameter = @{@"THREAD" : self.parentWKThread.encodeToDictionary,
                                  @"PAGE" : @(self.pageNumber)};
        [[ExtensionDelegate sharedInstance] sendCommand:loadCommand withCaller:self];
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
    
    [self.loadingIndicator stopLoading];
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

#pragma mark - Setters

- (void)setParentWKThread:(czzWKThread *)parentWKThread {
    _parentWKThread = parentWKThread;
    if (parentWKThread) {
        [self setTitle:[NSString stringWithFormat:@"%ld", (long)parentWKThread.ID]];
    }
}

@end



