//
//  czzFeedback.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFeedback.h"
#import "czzAppDelegate.h"

@implementation czzFeedback
@synthesize access_token;
@synthesize topic;
@synthesize title;
@synthesize time;
@synthesize name;
@synthesize content;
@synthesize emotion;

-(id)init {
    self = [super init];
    if (self) {
        access_token = @"null";
        topic = @"null";
        title = @"null";
        time = @"null";
        name = @"null";
        content = @"null";
        emotion = neutral;
    }
    return self;
}

-(BOOL)sendFeedback:(czzNotification*)notification{
    if (content.length <= 0) {
        DDLogDebug(@"need content");
        return NO;
    }
    NSString *targetHost = [AppDelegate.myhost stringByAppendingPathComponent:feedback_host];
    targetHost = [targetHost stringByAppendingFormat:@"access_token=%@&vendorID=%@&time=%@&name=%@&content=%@&emotion=%ld",
                  self.access_token, AppDelegate.vendorID, self.time, name, content, (long)emotion];
    if (notification) {
        targetHost = [targetHost stringByAppendingFormat:@"&notificationID=%@&title=%@&topic=%@", notification.notificationID, notification.title, notification.topic];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"UID"]) {
        targetHost = [targetHost stringByAppendingFormat:@"&UID=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"UID"]];
    }
    DDLogDebug(@"target url string = %@", targetHost);

    NSError *error;
    [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[targetHost stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] returningResponse:nil error:&error];
    if (error) {
        DDLogDebug(@"%@", error);
        return NO;
    }

    return YES;
}

-(NSString *)time {
    NSDateFormatter *simpleDateFormatter = [NSDateFormatter new];
    [simpleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

    return [simpleDateFormatter stringFromDate:[NSDate new]];
}

-(NSString *)access_token {
//#if DEBUG
//    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"access_token"])
//        return [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
//    return @"null";
//#endif
    return @"-";
}
@end
