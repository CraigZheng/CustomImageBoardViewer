//
//  WKInterfaceImage+ActivityIndicator.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface WKInterfaceImage (ActivityIndicator)

- (void)startLoading;
- (void)stopLoading;
@end
