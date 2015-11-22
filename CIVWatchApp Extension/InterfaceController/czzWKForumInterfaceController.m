//
//  czzWKForumViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWKForumInterfaceController.h"

#import "czzWatchKitCommand.h"

#define wkForumsRowControllerIdentifier @"wkForumsRowControllerIdentifier"

@interface czzWKForumRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *forumNameLabel;

@end

@implementation czzWKForumRowController
// Empty implementation.

@end

@interface czzWKForumInterfaceController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkForumsTableView;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *statusLabel;
@property (strong, nonatomic) NSArray *wkForums;
@end

@implementation czzWKForumInterfaceController


- (void)willActivate {
    DLog(@"%s", __PRETTY_FUNCTION__);
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    if (!self.wkForums.count)
    {
        [self loadForumData];   
    }
}

-(void)loadForumData {
    czzWatchKitCommand *loadForumCommand = [czzWatchKitCommand new];
    loadForumCommand.caller = NSStringFromClass(self.class);
    loadForumCommand.action = watchKitCommandLoadForumView;
    // Self is the caller.
    [[ExtensionDelegate sharedInstance] sendCommand:loadForumCommand
                                         withCaller:self];
}

#pragma mark - czzWKSessionDelegate
- (void)respondReceived:(NSDictionary *)response error:(NSError *)error {
    DLog(@"TODO: %s",__PRETTY_FUNCTION__);
    if (response.count) {
        NSArray *jsonForums = [response valueForKey:NSStringFromClass(self.class)];
        NSMutableArray *tempForumsArray = [NSMutableArray new];
        for (NSDictionary *jsonDict in jsonForums) {
            czzWKForum *forum = [[czzWKForum alloc] initWithDictionary:jsonDict];
            if (forum) {
                [tempForumsArray addObject:forum];
            }
        }
        self.wkForums = [tempForumsArray copy];
        [self reloadTableView];
        [self.statusLabel setHidden:YES];
    } else if (error) {
        [self.statusLabel setText:error.description];
        [self.statusLabel setHidden:NO];
    }
}

#pragma mark - TableView
-(void)reloadTableView {
    [self.wkForumsTableView setNumberOfRows:self.wkForums.count withRowType:wkForumsRowControllerIdentifier];
    [self.wkForums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        czzWKForumRowController *rowController = [self.wkForumsTableView rowControllerAtIndex:idx];
        [rowController.forumNameLabel setText:[(czzWKForum*)obj name]];
    }];
}

#pragma mark - Segue events
-(id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    czzWKForum *selectedForum = [self.wkForums objectAtIndex:rowIndex];
    
    return @{@(watchKitCommandLoadForumView) : [selectedForum encodeToDictionary]};
}

@end


