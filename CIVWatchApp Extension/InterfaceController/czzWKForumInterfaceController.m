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


@end

@interface czzWKForumInterfaceController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkForumsTableView;
@property (strong, nonatomic) NSMutableArray *wkForums;
@end

@implementation czzWKForumInterfaceController


- (void)willActivate {
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


