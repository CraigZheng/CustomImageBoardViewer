//
//  czzThreadSuggestion.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzThreadSuggestion.h"

@implementation czzThreadSuggestion

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (self) {
        _title = [dictionary objectForKey:@"title"];
        _content = [dictionary objectForKey:@"content"];
        if ([[dictionary objectForKey:@"url"] length]) {
            _url = [NSURL URLWithString:[dictionary objectForKey:@"url"]];
        }
    }
    return self;
}

@end
