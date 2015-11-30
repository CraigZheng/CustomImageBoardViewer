//
//  czzWKThread.h
//  CustomImageBoardViewer
//
//  Created by Craig on 18/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzWKThread : NSObject

@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *thumbnailFile;
@property (nonatomic, strong) NSString *imageFile;

@property (nonatomic, strong) NSDate *postDate;

-(instancetype)initWithDictionary:(NSDictionary*)dict;
-(NSDictionary*)encodeToDictionary;
@end