//
//  czzWatchKitCommand.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 19/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchKitCommand.h"

NSString * const kWatchkitCommandCaller = @"CALLER";
NSString * const kWatchkitCommandAction = @"ACTION";
NSString * const kWatchkitCommandParameter = @"PARAMETER";

@implementation czzWatchKitCommand

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    self.caller = [dict objectForKey:kWatchkitCommandCaller];
    self.action = [[dict objectForKey:kWatchkitCommandAction] integerValue];
    self.parameter = [dict objectForKey:kWatchkitCommandParameter];
    if (!self.caller || !self.action) {
        self = nil;
    }
    return self;
}

- (NSDictionary *)encodeToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:self.caller forKey:kWatchkitCommandCaller];
    [dict setObject:@(self.action) forKey:kWatchkitCommandAction];
    if (self.parameter)
        [dict setObject:self.parameter forKey:kWatchkitCommandParameter];
    return dict;
}

- (NSString *)jsonDictionary {
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self encodeToDictionary] options:NSJSONWritingPrettyPrinted error:nil]
                                 encoding:NSUTF8StringEncoding];
    DLog(@"jsonDict : %@", jsonString);
    return jsonString;
}

- (NSString *)description {
    return self.jsonDictionary;
}

@end
