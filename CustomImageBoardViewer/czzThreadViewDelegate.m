//
//  czzThreadTableViewDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadViewDelegate.h"

@implementation czzThreadViewDelegate

-(instancetype)init {
    self = [super init];
    if (self) {
        //set up custom edit menu
        UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:NSSelectorFromString(@"menuActionReply:")];
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:NSSelectorFromString(@"menuActionCopy:")];
        UIMenuItem *openMenuItem = [[UIMenuItem alloc] initWithTitle:@"打开链接" action:NSSelectorFromString(@"menuActionOpen:")];
        UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"高亮他" action:NSSelectorFromString(@"menuActionHighlight:")];
        //    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
        [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, /*searchMenuItem,*/ openMenuItem]];
        [[UIMenuController sharedMenuController] update];
    }
    return self;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do nothing for now
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.viewModelManager.threads.count) {
        return YES;
    }
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}
-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
}


+(instancetype)initWithViewModelManager:(czzThreadViewModelManager *)viewModelManager {
    czzThreadViewDelegate *sharedDelegate = [czzThreadViewDelegate sharedInstance];
    sharedDelegate.viewModelManager = viewModelManager;
    return sharedDelegate;
}


+ (instancetype)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

@end
