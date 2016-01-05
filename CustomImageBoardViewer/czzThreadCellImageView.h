//
//  czzThreadCellImageView.h
//  CustomImageBoardViewer
//
//  Created by Craig on 4/01/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "CPLoadFromNibView.h"

@class czzThreadCellImageView;
@protocol czzThreadCellImageViewDelegate <NSObject>
@optional
-(void)cellImageViewTapped:(czzThreadCellImageView *)imageView;
@end

@interface czzThreadCellImageView : CPLoadFromNibView
@property (nonatomic, weak) id<czzThreadCellImageViewDelegate> delegate;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL bigImageMode;
@end
