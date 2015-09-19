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
        dateFormatter.dateFormat = @"h:ma";
        
        [self.wkThreadContentLabel setText:wkThread.content];
        [self.wkThreadInformationLabel setText:[NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:wkThread.postDate], wkThread.name]];
        
        //TODO - figure out why is it not working
        if (wkThread.thumbnailFile.length) {
            [self.wkThreadThumbnailImage setImage:[UIImage imageNamed:@"01.png"]];
        } else {
            [self.wkThreadThumbnailImage setImage:[UIImage imageNamed:@"02.png"]];
        }
    }
}
@end
