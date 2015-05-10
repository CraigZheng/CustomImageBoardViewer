//
//  czzForumGroup.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzForum.h"

@interface czzForumGroup : NSObject
@property NSString *area;
@property NSMutableArray *forums;

-(NSArray*)allForums;
-(NSArray*)availableForums;
-(id)initWithJSONDictionary:(NSDictionary*)jsonDict;
-(NSDictionary*)toDictionary;
@end
