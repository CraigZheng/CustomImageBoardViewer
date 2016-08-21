//
//  czzTextSizeSelectorViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzSettingsCentre.h"

@class czzTextSizeSelectorViewController;
@protocol czzTextSizeSelectorViewControllerProtocol <NSObject>

- (void)textSizeSelected:(czzTextSizeSelectorViewController*)viewController textSize:(ThreadViewTextSize)size;

@end

@interface czzTextSizeSelectorViewController : UIViewController

@property (nonatomic, weak) id<czzTextSizeSelectorViewControllerProtocol> delegate;

@end
