//
//  czzForumGroup.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumGroup.h"

@interface czzForumGroup ()
@property NSMutableArray *_availableForums;
@end

@implementation czzForumGroup
@synthesize area, forums, _availableForums;

-(id)init{
    self = [super init];
    if (self){
        self.forums = [NSMutableArray new];
    }
    return self;
}

-(NSArray *)allForums {
    return forums;
}

-(NSArray *)availableForums {
    if (!_availableForums) {
        if (self.allForums.count) {
            _availableForums = [NSMutableArray new];
            for (czzForum *forum in self.allForums) {
                if (!forum.lock)
                    [_availableForums addObject:forum];
            }
        }
    }
    return _availableForums;
}

-(id)initWithJSONDictionary:(NSDictionary *)jsonDict {
    self = [self init];
    if (self) {
        if (jsonDict) {
            @try {
                for (NSString *key in jsonDict.allKeys) {
                    area = key;
                    for (NSDictionary *subDict in [jsonDict objectForKey:key]) {
                        czzForum *forum = [[czzForum alloc] initWithJSONDictionary:subDict];
                        if (forum)
                        {
                            [forums addObject:forum];
                        }
                    }
                }
            }
            @catch (NSException *exception) {
                DLog(@"%@", exception);
            }
        }
    }
    return self;
}

-(NSDictionary *)toDictionary {
    if (self.allForums.count) {
        NSMutableArray *tempAllForums = [NSMutableArray new];
        for (czzForum *forum in self.allForums) {
            [tempAllForums addObject:[forum toDictionary]];
        }
        return [NSDictionary dictionaryWithObject:tempAllForums forKey:area];
    }
    return nil;
}
@end
