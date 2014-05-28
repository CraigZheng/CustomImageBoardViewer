//
//  czzFeedback.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFeedback.h"

@implementation czzFeedback
@synthesize access_token;
@synthesize vendorID;
@synthesize topic;
@synthesize title;
@synthesize time;
@synthesize name;
@synthesize content;
@synthesize emotion;


-(BOOL)sendFeedback{
    if (content.length <= 0) {
        NSLog(@"need content");
        return NO;
    }
    NSString *targetHost = feedback_host;
    NSDateFormatter *simpleDateFormatter = [NSDateFormatter new];
    [simpleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    targetHost = [targetHost stringByAppendingFormat:@"?access_token=%@&vendorID=%@&topic=%@&title=%@&time=%@&name=%@&content=%@&emotion=%@",
                  access_token, vendorID, topic, title, time, name, content, emotion];
    NSError *error;
    [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:targetHost]] returningResponse:nil error:&error];
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }
    return YES;
}

-(NSString *)vendorID {
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

-(NSDate *)time {
    return [NSDate new];
}

-(NSString *)access_token {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
}
@end
