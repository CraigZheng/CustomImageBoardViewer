//
//  czzThreadViewCommandStatusCellViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, czzThreadViewCommandStatusCellViewType) {
    czzThreadViewCommandStatusCellViewTypeLoadMore = 0,
    czzThreadViewCommandStatusCellViewTypeReleaseToLoadMore = 1,
    czzThreadViewCommandStatusCellViewTypeNoMore = 2,
    czzThreadViewCommandStatusCellViewTypeLoading = 3
};

@interface czzThreadViewCommandStatusCellViewController : UIViewController

@property (nonatomic, assign) czzThreadViewCommandStatusCellViewType cellType;
@end
