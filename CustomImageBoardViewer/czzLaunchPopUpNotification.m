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
            self.enable = [[jsonDict objectForKey:@"enable"] boolValue];
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"ddddmmyyhh";
            NSDate *date = [formatter dateFromString:[jsonDict objectForKey:@"date"]];
            self.notificationDate = date;
            self.notificationContent = [[jsonDict objectForKey:@"content"] stringValue];
        } else {
            DLog(@"%@", error);
        }
    }
    return self;
}


#pragma mark - Showing - hiding.

- (Boolean)tryShow {
    Boolean showed = false;
    // TODO: calculate the last display time, and show only if necessary.
    return showed;
}

- (void)show {
    // TODO: show and record date time.
}

- (void)hide {
    // TODO: dismiss any showing notification.
}

@end
