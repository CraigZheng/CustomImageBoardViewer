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
#import "WKInterfaceImage+ActivityIndicator.h"
#import "ExtensionDelegate.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController() <czzWKSessionDelegate>

@property (strong, nonatomic) NSMutableArray *wkThreads;
@property (strong, nonatomic) czzWKForum *selectedForum;
@property (strong, nonatomic) czzWKThread *selectedThread;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *reloadButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *loadingIndicator;
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
}

-(void)reloadData {
    [self loadMore:NO];
}

-(void)loadMore:(BOOL)more {
    [self.loadingIndicator startLoading];
    [self.reloadButton setEnabled:NO];
    // Constructing and sending of the command.
    czzWatchKitCommand *loadCommand = [czzWatchKitCommand new];
    loadCommand.caller = NSStringFromClass(self.class);
    loadCommand.action = watchKitCommandLoadHomeView;
    loadCommand.parameter = @{@"FORUM" : self.selectedForum.encodeToDictionary,
                              @"PAGE" : @(1)};
    [[ExtensionDelegate sharedInstance] sendCommand:loadCommand
                                         withCaller:self];
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
    NSArray *jsonThreads = [response objectForKey:NSStringFromClass(self.class)];
    [self.wkThreads removeAllObjects];
    for (NSDictionary *dict in jsonThreads) {
        czzWKThread *wkThread = [[czzWKThread alloc] initWithDictionary:dict];
        [self.wkThreads addObject:wkThread];
    }
    [self reloadTableView];
    [self.loadingIndicator stopLoading];
    [self.reloadButton setEnabled:YES];
}

#pragma mark - segue
-(id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    self.selectedThread = [self.wkThreads objectAtIndex:rowIndex];
    
    return @{@(watchKitCommandLoadThreadView) : [self.selectedThread encodeToDictionary]};
}

#pragma mark - Getter

- (NSMutableArray *)wkThreads {
    if (!_wkThreads) {
        _wkThreads = [NSMutableArray new];
    }
    return _wkThreads;
}

#pragma mark - TableView
-(void)reloadTableView {
    [self.wkThreadsTableView setNumberOfRows:self.wkThreads.count withRowType:wkHomeViewRowControllerIdentifier];
    
    [self.wkThreads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        czzWatchKitHomeRowController* theRow = [self.wkThreadsTableView rowControllerAtIndex:idx];
        theRow.shouldTruncate = YES;
        theRow.wkThread = obj;
    }];
}

#pragma mark - Setters

- (void)setSelectedForum:(czzWKForum *)selectedForum {
    _selectedForum = selectedForum;
    if (selectedForum) {
        [self setTitle:selectedForum.name];
    }
}

@end



