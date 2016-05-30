//
//  czzPopularThreadsManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#define PopularThreadsManager [czzPopularThreadsManager sharedInstance]

#import <Foundation/Foundation.h>

@class czzThreadSuggestion, czzPopularThreadsManager;

@protocol czzPopularThreadsManagerDelegate <NSObject>

- (void)popularThreadsManagerDidUpdate:(czzPopularThreadsManager *)manager;

@end
                                        
@interface czzPopularThreadsManager : NSObject

@property (nonatomic, readonly) NSArray<NSDictionary<NSString *, NSArray<czzThreadSuggestion*> *> *> *suggestions;

@end
