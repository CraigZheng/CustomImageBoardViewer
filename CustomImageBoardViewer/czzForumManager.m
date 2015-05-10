//
//  czzForumManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzForumManager.h"

@implementation czzForumManager
@synthesize availableForums, allForums, forumDownloader;

-(instancetype)init {
    self = [super init];
    if (self) {
        //load default forumID json file to avoid crash caused by bad network connection
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_forumID" ofType:@"json"];
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        NSArray *defaultForums = [self parseJsonForForum:JSONData];
        
        NSMutableArray *tempAll = [NSMutableArray new];
        
        for (czzForum *forum in defaultForums) {
            NSDictionary *dict = [forum toDictionary];
            [tempAll addObject:dict];
        }
        @try {
            NSData *data = [NSJSONSerialization dataWithJSONObject:tempAll options:0 error:nil];
            NSString *jsonForums = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DLog(@"%@", jsonForums);
        } @catch (NSError *e) {
            DLog(@"%@", e);
        }
    }
    return self;
}

-(NSArray*)parseJsonForForum:(NSData*)jsonData {
    NSError* error;
    NSMutableArray *newForums = [NSMutableArray new];
    
    NSDictionary *jsonDict;
    if (jsonData)
        jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    else {
        error = [NSError errorWithDomain:@"Empty Data" code:999 userInfo:nil];
    }
    if (!error) {
        NSArray *rawForumData = [jsonDict valueForKey:@"forum"];
        for (NSDictionary* rawForum in rawForumData) {
            czzForum *newForum = [[czzForum alloc] initWithJSONDictionary:rawForum];
            if (newForum)
                [newForums addObject:newForum];
        }
    }
    return newForums;
}


#pragma mark - czzURLDownloaderProtocol
-(void)downloadOf:(NSURL *)url successed:(BOOL)successed result:(NSData *)downloadedData {
    
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
