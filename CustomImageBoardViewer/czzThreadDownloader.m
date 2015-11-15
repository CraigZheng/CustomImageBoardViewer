//
//  czzThreadDownloader.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 15/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadDownloader.h"

@interface czzThreadDownloader() <czzURLDownloaderProtocol, czzJSONProcessorDelegate>
@property (nonatomic, strong) czzURLDownloader *urlDownloader;
@property (nonatomic, strong) czzJSONProcessor *jsonProcessor;
@end

@implementation czzThreadDownloader


@end
