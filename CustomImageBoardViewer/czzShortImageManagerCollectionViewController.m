//
//  czzShortImageManagerCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzShortImageManagerCollectionViewController.h"
#import "UIView+MGBadgeView.h"
#import "czzAppDelegate.h"
#import "czzImageCentre.h"
#import "czzImageDownloader.h"
#import "KLCPopup.h"

@interface czzShortImageManagerCollectionViewController ()<czzImageCentreProtocol>
@property czzImageCentre *imageCentre;
@property NSArray *downloaders;
@property KLCPopup *popup;
@end

@implementation czzShortImageManagerCollectionViewController
@synthesize delegate;
@synthesize imageCentre;
@synthesize downloaders;
@synthesize popup;
@synthesize managerCollectionView;
@synthesize isShowing;

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [managerCollectionView reloadData];
}

- (IBAction)tapOnViewAction:(id)sender {
    isShowing = NO;
    [popup dismiss:YES];
}

-(void)show {
    imageCentre = [czzImageCentre sharedInstance];
    downloaders = imageCentre.currentImageDownloaders.array;
    if (downloaders.count <= 0)
    {
        DLog(@"No currently downloading image, return...");
        return;
    }
    popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    
    [popup showWithLayout:KLCPopupLayoutCenter];
    
    isShowing = YES;
}

-(void)updateProgressForDownloader:(czzImageDownloader *)downloader {
    [managerCollectionView reloadData];
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//    return 10;
    return downloaders.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];

    UIImageView *downloaderThumbnailImageView = (UIImageView*) [cell viewWithTag:1];
    UILabel *downloaderLabel = (UILabel*) [cell viewWithTag:2];
    czzImageDownloader *currentDownloader = [downloaders objectAtIndex:indexPath.row];
    //thumbnail
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:[[currentDownloader targetURLString] lastPathComponent]]];
    if (thumbnailImage) {
        downloaderThumbnailImageView.image = thumbnailImage;
    } else {
        downloaderThumbnailImageView.image = [UIImage imageNamed:@"icon.png"];
    }
    //progress label
    downloaderLabel.text = [NSString stringWithFormat:@"%.1f%%", [currentDownloader progress] * 100];
    
    return cell;
}


@end
