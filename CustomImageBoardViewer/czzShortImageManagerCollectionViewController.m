//
//  czzShortImageManagerCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzShortImageManagerCollectionViewController.h"
#import "UIView+MGBadgeView.h"
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

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    imageCentre = [czzImageCentre sharedInstance];
    imageCentre.delegate = self;
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    downloaders = imageCentre.currentImageDownloaders.allObjects;
}

- (IBAction)tapOnViewAction:(id)sender {
    [popup dismiss:YES];
}

-(void)show {
    popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    
    [popup showWithLayout:KLCPopupLayoutCenter];
}

#pragma mark - czzImageDownloaderProtocol
-(void)imageCentreDownloadUpdated:(czzImageCentre *)imgCentre downloader:(czzImageDownloader *)downloader progress:(CGFloat)progress {
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
    return downloaders.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    DLog(@"adgs");
}
@end
