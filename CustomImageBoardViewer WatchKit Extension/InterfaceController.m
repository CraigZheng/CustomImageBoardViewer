//
//  InterfaceController.m
//  CustomImageBoardViewer WatchKit Extension
//
//  Created by Craig on 9/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "InterfaceController.h"
#import "czzHomeViewModelManager.h"

@interface InterfaceController() <czzHomeViewModelManagerDelegate>
@property (nonatomic, strong) czzHomeViewModelManager *viewModelManager;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *firstRowLabel;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    self.viewModelManager.delegate = self;
    [self.viewModelManager refresh];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#pragma mark - czzHomeViewModelManagerDelegate
- (void)viewModelManager:(czzHomeViewModelManager *)threadList processedThreadData:(BOOL)wasSuccessul newThreads:(NSArray *)newThreads allThreads:(NSArray *)allThreads {
    if (wasSuccessul) {
        czzThread *firstThread = newThreads.firstObject;
        [self.firstRowLabel setText:firstThread.content.string];
    } else {
        NSLog(@"UNSUCCESSFUL");
    }
}

#pragma mark - Getters
- (czzHomeViewModelManager *)viewModelManager {
    return [czzHomeViewModelManager sharedManager];
}
@end



