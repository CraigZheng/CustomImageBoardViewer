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
        
        NSString *threadContent = wkThread.content;
        if (self.shouldTruncate && threadContent.length > 40) {
            threadContent = [NSString stringWithFormat:@"%@...", [threadContent substringToIndex:40]];
        }
        [self.wkThreadContentLabel setText:threadContent];
        [self.wkThreadInformationLabel setText:[NSString stringWithFormat:@"%@-%@", [dateFormatter stringFromDate:wkThread.postDate], wkThread.name]];
        
        //TODO: show actual image
        
        if (wkThread.imageFile.length) {
            [self.wkThreadThumbnailImage setImage:[[UIImage imageNamed:@"picture.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        } else {
            [self.wkThreadThumbnailImage setImage:nil];
        }
    }
}
@end
