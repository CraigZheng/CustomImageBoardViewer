//
//  czzBannerView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CPLoadFromNibView.h"

@class czzBannerView;
@protocol czzBannerViewDelegate <NSObject>
- (void)bannerViewDidTouch:(czzBannerView *)bannerView;
- (void)bannerView:(czzBannerView *)bannerView didTouchButton:(UIButton *)button;

@end

@interface czzBannerView : CPLoadFromNibView
@property (nonatomic, weak) id<czzBannerViewDelegate> delegate;
@property (nonatomic, strong) NSString *title;
@end
