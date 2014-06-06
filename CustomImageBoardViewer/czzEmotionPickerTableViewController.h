//
//  czzEmotionPickerTableViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzFeedback.h"
#import "FPPopoverController.h"

@protocol czzEmotionPickerTableViewDelegate <NSObject>
-(void)emotionPicked:(EMOTIONS)emotion;
@end

@interface czzEmotionPickerTableViewController : UITableViewController
@property id<czzEmotionPickerTableViewDelegate> delegate;
@property FPPopoverController *popoverController;
@end
