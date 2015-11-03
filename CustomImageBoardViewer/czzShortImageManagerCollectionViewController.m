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
#import "czzImageCacheManager.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzImageViewerUtil.h"
#import "KLCPopup.h"

@interface czzShortImageManagerCollectionViewController ()<czzImageDownloaderManagerDelegate>
@property (strong, nonatomic) KLCPopup *popup;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) NSMutableArray *downloadedImages;
@property (readonly, nonatomic) NSArray *downloaders;
@end

@implementation czzShortImageManagerCollectionViewController
@synthesize delegate;
@synthesize popup;
@synthesize managerCollectionView;
@synthesize isShowing;
@synthesize placeholderView;
@synthesize imageViewerUtil;
@synthesize hostViewController;

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";
static NSString *downloadedImageCellIdentifier = @"downloaded_image_view_cell";

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[czzImageDownloaderManager sharedManager] addDelegate:self];
    }
    return self;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[czzImageDownloaderManager sharedManager] addDelegate:self];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [managerCollectionView reloadData];
    if (self.downloadedImages.count == 0 && self.downloaders.count == 0)
    {
        placeholderView.hidden = NO;
    } else {
        placeholderView.hidden = YES;
    }
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (IBAction)tapOnViewAction:(id)sender {
    isShowing = NO;
    [popup dismiss:YES];
}

-(void)show {
    popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    
    [popup showWithLayout:KLCPopupLayoutCenter];
    
    isShowing = YES;
}

#pragma mark - Getter
-(NSArray *)downloaders {
    return [[[czzImageDownloaderManager sharedManager] imageDownloaders] allObjects];
}

-(NSMutableArray *)downloadedImages {
    if (!_downloadedImages) {
        _downloadedImages = [NSMutableArray new];
    }
    return _downloadedImages;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0)
        return self.downloaders.count;
    return self.downloadedImages.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];
        
        UIImageView *downloaderThumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        UILabel *downloaderLabel = (UILabel*) [cell viewWithTag:2];
        czzImageDownloader *currentDownloader = [self.downloaders objectAtIndex:indexPath.row];
        //thumbnail
        UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:[[currentDownloader targetURLString] lastPathComponent]]];
        if (thumbnailImage) {
            downloaderThumbnailImageView.image = thumbnailImage;
        } else {
            downloaderThumbnailImageView.image = [UIImage imageNamed:@"icon.png"];
        }
        //progress label
        NSString *progressText = [NSString stringWithFormat:@"%.1f%%", [currentDownloader progress] * 100];
        downloaderLabel.text = progressText;
        return cell;
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:downloadedImageCellIdentifier forIndexPath:indexPath];
        
        UIImageView *thumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        NSString *imgPath = [self.downloadedImages objectAtIndex:indexPath.row];
        UIImage *fullImg = [UIImage imageWithContentsOfFile:imgPath];
        UIImage *thumbnailImg = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:imgPath.lastPathComponent]];
        
        thumbnailImageView.image = thumbnailImg ? thumbnailImg : fullImg;
        
        return cell;
    }
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        czzImageDownloader *imageDownloader = [self.downloaders objectAtIndex:indexPath.row];
        [[czzImageDownloaderManager sharedManager] stopDownloadingImage:imageDownloader.imageURLString.lastPathComponent];
    }
    //downloaded image section
    else if (indexPath.section == 1) {
        //if parent view controller is not nil, show in parent view
        if (hostViewController) {
            imageViewerUtil = [czzImageViewerUtil new];
            [imageViewerUtil showPhotos:self.downloadedImages withIndex:indexPath.row];
        } else {
            NSString *imgPath = [self.downloadedImages objectAtIndex:indexPath.row];
            if (delegate && [delegate respondsToSelector:@selector(userTappedOnImageWithPath:)]) {
                [delegate userTappedOnImageWithPath:imgPath];
            }
        }
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedUpdated:(czzImageDownloader *)downloader imageName:(NSString *)imageName progress:(CGFloat)progress {
    [self.managerCollectionView reloadData];
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    // This view controller cares only for the full size images.
    if (!downloader.isThumbnail) {
        if (success) {
            if (self.downloadedImages.count)
                [self.downloadedImages insertObject:downloader.savePath atIndex:0];
            else
                [self.downloadedImages addObject:downloader.savePath];
        }
        [self.managerCollectionView reloadData];
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:SHORT_IMAGE_MANAGER_VIEW_CONTROLLER];
}
@end
