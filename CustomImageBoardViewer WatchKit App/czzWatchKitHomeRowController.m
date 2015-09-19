//
//  czzWatchKitHomeRowController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchKitHomeRowController.h"

@implementation czzWatchKitHomeRowController

#pragma mark - Setters
- (void)setWkThread:(czzWKThread *)wkThread {
    _wkThread = wkThread;
    
    if (wkThread) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"h:m";
        
        [self.wkThreadContentLabel setText:wkThread.content];
        [self.wkThreadInformationLabel setText:[NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:wkThread.postDate], wkThread.name]];
    }
}
@end
