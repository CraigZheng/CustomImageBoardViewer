//
//  czzWKForum.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzWKForum : NSObject

@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) NSInteger forumID;

-(instancetype)initWithDictionary:(NSDictionary*)dict;
-(NSDictionary*)encodeToDictionary;
@end
