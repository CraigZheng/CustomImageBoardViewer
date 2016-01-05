//
//  czzThreadCellImageView.m
//  CustomImageBoardViewer
//
//  Created by Craig on 4/01/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzThreadCellImageView.h"

@interface czzThreadCellImageView()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maximumTraillingConstraint;

@end

@implementation czzThreadCellImageView

- (void)renderContent {
    if (self.image) {
        self.imageView.image = self.image;
    } else {
        self.imageView.image = [UIImage imageNamed:@"Icon.png"];
    }
    if (self.bigImageMode) {
        self.maximumTraillingConstraint.priority = UILayoutPriorityRequired - 1;
        self.imageView.contentMode = UIViewContentModeTop;
    } else {
        self.maximumTraillingConstraint.priority = 1;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
}

- (IBAction)tapOnImageView:(id)sender {
    if (self.image && [self.delegate respondsToSelector:@selector(cellImageViewTapped:)]) {
        [self.delegate cellImageViewTapped:self];
    }
}

#pragma mark - Setters

- (void)setImage:(UIImage *)image {
    _image = image;
    [self renderContent];
}

@end
