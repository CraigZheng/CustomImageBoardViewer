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

@end

@implementation czzThreadCellImageView

- (void)renderContent {
    if (self.image) {
        self.imageView.image = self.image;
    } else {
        self.imageView.image = [UIImage imageNamed:@"Icon.png"];
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
