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

@interface czzShortImageManagerCollectionViewController ()<czzImageDownloaderManagerDelegate>
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) NSArray *downloadedImages;
@property (readonly, nonatomic) NSArray *downloaders;
@end

@implementation czzShortImageManagerCollectionViewController
@synthesize delegate;
@synthesize managerCollectionView;
@synthesize placeholderView;
@synthesize imageViewerUtil;

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";
static NSString *downloadedImageCellIdentifier = @"downloaded_image_view_cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
    self.dismissOnTap = NO;
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
}

- (IBAction)tapOnBackgroundViewAction:(id)sender {
    UITapGestureRecognizer *tapSender = sender;
    // If the tap gesture is located outside of the collection view.
    if (!CGRectContainsPoint(self.managerCollectionView.frame, [tapSender locationInView:self.view])) {
        [self dismiss];
    }
}

- (void)dismiss {
    if (self.isModal) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.navigationController.childViewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        DLog(@"%@ cannot be dismissed", NSStringFromClass(self.class));
    }
}

#pragma mark - Getter
-(NSArray *)downloaders {
    return [[[czzImageDownloaderManager sharedManager] imageDownloaders] allObjects];
}

-(NSArray *)downloadedImages {
    return [[czzImageDownloaderManager sharedManager] downloadedImages];
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
        [self dismiss];
    }
    //downloaded image section
    else if (indexPath.section == 1) {
        //if parent view controller is not nil, show in parent view
        [self dismissViewControllerAnimated:YES completion:^{
            DLog(@"%s", __PRETTY_FUNCTION__);
            if (self.delegate) {
                NSString *imgPath = [self.downloadedImages objectAtIndex:indexPath.row];
                if (delegate && [delegate respondsToSelector:@selector(userTappedOnImageWithPath:)]) {
                    [delegate userTappedOnImageWithPath:imgPath];
                }
            } else {
                imageViewerUtil = [czzImageViewerUtil new];
                [imageViewerUtil showPhotos:self.downloadedImages withIndex:indexPath.row];
            }
        }];
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedUpdated:(czzImageDownloader *)downloader imageName:(NSString *)imageName progress:(CGFloat)progress {
    [self.managerCollectionView reloadData];
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    // This view controller cares only for the full size images.
    if (!downloader.isThumbnail) {
        [self.managerCollectionView reloadData];
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"ImageManagerStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:SHORT_IMAGE_MANAGER_VIEW_CONTROLLER];
}
@end
