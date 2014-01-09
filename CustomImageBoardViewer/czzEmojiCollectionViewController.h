//
//  czzEmojiCollectionViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 9/01/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol czzEmojiCollectionViewControllerDelegate <NSObject>
-(void)emojiSelected:(NSString*)emoji;
@end

@interface czzEmojiCollectionViewController : UIViewController
@property (strong, nonatomic) IBOutlet UICollectionView *emojiCollectionView;
@property id<czzEmojiCollectionViewControllerDelegate> delegate;
- (IBAction)cancelAction:(id)sender;

@end
