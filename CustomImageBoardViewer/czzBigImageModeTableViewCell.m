//
//  czzBigImageModeTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 27/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBigImageModeTableViewCell.h"

@implementation czzBigImageModeTableViewCell

- (void)renderContent {
    [super renderContent];
    NSString *imageName = self.thread.imgSrc.lastPathComponent;
    if (imageName.length && [[czzImageCacheManager sharedInstance] hasImageWithName:imageName]) {
        UIImage *fullsizeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[[czzImageCacheManager sharedInstance] pathForImageWithName:imageName]]];
        self.cellImageView.image = fullsizeImage;
    }
}

@end
