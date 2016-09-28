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
@property (assign, nonatomic) BOOL isUpdating;
@property (assign, nonatomic) BOOL contentUpdated;
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
- (void)didAppear {
    [super didAppear];
    // self.wkThreads will always include a parent thread.
    if (!self.isUpdating) {
        [self.moreButton setEnabled:YES];
        [self.loadingIndicator stopLoading];
        if (self.wkThreads.count <= 1) {
            [self loadMore];
        } else if (self.contentUpdated) {
            [self loadData];
        }
    } else {
        [self.moreButton setEnabled:NO];
        [self.loadingIndicator startLoading];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)loadData {
    if (self.contentUpdated) {
        [self reloadTableView];
        [self.loadingIndicator stopLoading];
        [self.moreButton setEnabled:YES];
        self.contentUpdated = YES;
    }
}

-(void)loadMore {
    if (self.parentWKThread) {
        self.isUpdating = YES;
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
    if (response.count && !error) {
        self.pageNumber ++;
        NSArray *jsonThreads = [response objectForKey:NSStringFromClass(self.class)];
        for (NSDictionary *jsonDict in jsonThreads) {
            czzWKThread *wkThread = [[czzWKThread alloc] initWithDictionary:jsonDict];
            [self.wkThreads addObject:wkThread];
        }
        self.contentUpdated = YES;
    }
    self.isUpdating = NO;
    [self.loadingIndicator stopLoading];
    [self.moreButton setEnabled:YES];
    [self loadData];
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



