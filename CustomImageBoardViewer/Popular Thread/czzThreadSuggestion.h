//
//  czzThreadSuggestion.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzThreadSuggestion : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
