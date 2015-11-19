//
//  czzWKForumViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWKForumViewController.h"

#import "czzWatchKitCommand.h"

#define wkForumsRowControllerIdentifier @"wkForumsRowControllerIdentifier"

@interface czzWKForumRowController : NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *forumNameLabel;

@end

@implementation czzWKForumRowController


@end

@interface czzWKForumViewController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkForumsTableView;
@property (strong, nonatomic) NSMutableArray *wkForums;
@end

@implementation czzWKForumViewController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    if (!self.wkForums.count)
    {
        [self loadForumData];   
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

-(void)loadForumData {
#warning TODO: MADE IT COMPATIBLE WITH WATCH OS 2
//    [WKInterfaceController openParentApplication:@{watchKitCommandKey : @(watchKitCommandLoadForumView)} reply:^(NSDictionary *replyInfo, NSError *error) {
//        self.wkForums = [NSMutableArray new];
//        for (NSDictionary *dict in [replyInfo objectForKey:@(watchKitCommandLoadForumView)]) {
//            czzWKForum *forum = [[czzWKForum alloc] initWithDictionary:dict];
//            [self.wkForums addObject:forum];
//        }
//        [self reloadTableView];
//    }];
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


