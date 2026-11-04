//
//  ProgressOverlay.h
//  CustomImageBoardViewer
//
//  Native replacement for MBProgressHUD.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressOverlay : UIView

@property (nonatomic, assign) float progress;
@property (nonatomic, copy, nullable) NSString *statusText;

+ (instancetype)showInView:(UIView *)view;
+ (instancetype)showDeterminateInView:(UIView *)view;
+ (void)hideFromView:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
