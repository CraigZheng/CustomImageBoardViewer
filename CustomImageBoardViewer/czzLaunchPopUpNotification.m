//
//  czzLaunchPopUpNotification.m
//  CustomImageBoardViewer
//
//  Created by Craig on 24/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzLaunchPopUpNotification.h"

static NSString * const kLastNotificationDisplayTime = @"kLastNotificationDisplayTime";

@implementation czzLaunchPopUpNotification

- (instancetype)initWithJson:(NSString *)json {
    if (json.length) {
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&error];
        if (!error) {
            self = [super init];
            self.
        } else {
            DLog(@"%@", error);
        }
    }
    return self
}

@end
