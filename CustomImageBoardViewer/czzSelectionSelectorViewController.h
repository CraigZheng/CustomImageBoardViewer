//
//  czzTextSizeSelectorViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzSettingsCentre.h"

@class czzSelectionSelectorViewController;
@protocol czzSelectionSelectorViewControllerProtocol <NSObject>

- (void)selectorViewController:(czzSelectionSelectorViewController*)viewController selectedIndex:(NSInteger)index;

@end

@interface czzSelectionSelectorViewController : UIViewController

@property (nonatomic, weak) id<czzSelectionSelectorViewControllerProtocol> delegate;
@property (nonatomic, strong) NSArray<NSString *> *selections;

@end
