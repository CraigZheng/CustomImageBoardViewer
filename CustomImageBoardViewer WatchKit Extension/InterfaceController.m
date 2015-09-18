//
//  InterfaceController.m
//  CustomImageBoardViewer WatchKit Extension
//
//  Created by Craig on 9/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "InterfaceController.h"
#import "czzWKThread.h"

@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *firstRowLabel;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [WKInterfaceController openParentApplication:@{@"VIEW" : @"HOME"} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"MAIN APP CALLED COMPLETION HANDLER");
        NSArray *threadDictionaries = [replyInfo objectForKey:@"HOME_VIEW_THREADS"];
        for (NSDictionary *dict in threadDictionaries) {
            czzWKThread *thread = [[czzWKThread alloc] initWithDictionary:dict];
            NSLog(@"thread: %@", thread);
        }
    }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



