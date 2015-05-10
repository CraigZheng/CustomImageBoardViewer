//
//  czzForumManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzForumManager.h"

@interface czzForumManager() <czzURLDownloaderProtocol>
@property czzURLDownloader *forumDownloader;

@end

@implementation czzForumManager
@synthesize allForumGroups, forumDownloader;

-(instancetype)init {
    self = [super init];
    if (self) {
        //load default forumID json file to avoid crash caused by bad network connection
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_forums" ofType:@"json"];
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        NSArray *defaultForums = [self parseJsonForForum:JSONData];
        
        allForumGroups = [NSMutableArray arrayWithArray:defaultForums];
    }
    return self;
}

-(void)updateForum {
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifdef DEBUG
    versionString = @"DEBUG";
#endif
    NSString *forumString = [[settingCentre forum_list_url] stringByAppendingString:[NSString stringWithFormat:@"?version=%@", [NSString stringWithFormat:@"%@-%@", bundleIdentifier, versionString]]];
    NSLog(@"Forum config URL: %@", forumString);

    if (forumDownloader) {
        [forumDownloader stop];
    }
    forumDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];
}

-(NSArray*)parseJsonForForum:(NSData*)jsonData {
    NSError* error;
    NSMutableArray *newForumGroup = [NSMutableArray new];
    
    NSDictionary *jsonDict;
    if (jsonData)
        jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else {
        error = [NSError errorWithDomain:@"Empty Data" code:999 userInfo:nil];
    }
    if (!error) {
        NSArray *rawForumData = [jsonDict valueForKey:@"forum"];
        for (NSDictionary* rawForum in rawForumData) {
            czzForumGroup *forumGroup = [[czzForumGroup alloc] initWithJSONDictionary:rawForum];
            if (forumGroup)
                [newForumGroup addObject:forumGroup];
        }
    }
    return newForumGroup;
}


#pragma mark - czzURLDownloaderProtocol
-(void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    if (successed)
        [self parseJsonForForum:downloadedData];
}

+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

@end
