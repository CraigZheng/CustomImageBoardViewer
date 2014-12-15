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

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    imageCentre = [czzImageCentre sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    downloaders = imageCentre.currentImageDownloaders.array;
    [managerCollectionView reloadData];
}

- (IBAction)tapOnViewAction:(id)sender {
    [popup dismiss:YES];
}

-(void)show {
//    if (imageCentre.currentImageDownloaders.count <= 0) {
//        DLog(@"Nothing to show for on screen image manager");
//        return;
//    }
    popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    
    [popup showWithLayout:KLCPopupLayoutCenter];
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
    DLog(@"thumbnail path: %@", [[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:[[[downloaders objectAtIndex:indexPath.row] targetURLString] lastPathComponent]]);
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:[[[downloaders objectAtIndex:indexPath.row] targetURLString] lastPathComponent]]];
    if (thumbnailImage) {
        downloaderThumbnailImageView.image = thumbnailImage;
    } else {
        downloaderThumbnailImageView.image = [UIImage imageNamed:@"icon.png"];
    }
    
    return cell;
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    DLog(@"adgs");
}
@end
