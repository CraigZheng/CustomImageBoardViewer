//
//  WKInterfaceImage+ActivityIndicator.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "WKInterfaceImage+ActivityIndicator.h"

@implementation WKInterfaceImage (ActivityIndicator)

- (void)startLoading {
    [self setHidden:NO];
    [self setImageNamed:@"Activity"];
    [self startAnimatingWithImagesInRange:NSMakeRange(0, 41)
                                 duration:1.0
                              repeatCount:0];
}

- (void)stopLoading {
    [self stopAnimating];
    [self setHidden:YES];
}
@end
