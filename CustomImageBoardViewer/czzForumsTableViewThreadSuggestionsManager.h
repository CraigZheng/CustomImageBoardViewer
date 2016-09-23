//
//  czzForumsTableViewThreadSuggestionsManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzPopularThreadsManager;

@interface czzForumsTableViewThreadSuggestionsManager : NSObject <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithPopularThreadsManager:(czzPopularThreadsManager *)manager;
@end
