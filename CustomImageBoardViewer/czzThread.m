//
//  czzThread.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThread.h"
#import "SMXMLDocument.h"
#import "GTMNSString+HTML.h"
#import "czzBlacklist.h"
#import "czzBlacklistEntity.h"
#import "czzImageCacheManager.h"
#import "NSString+HTML.h"
#import "czzSettingsCentre.h"
#import "czzURLDownloader.h"
#import "NSDictionary+Util.h"

@interface czzThread()
@end

@implementation czzThread

-(id)init {
    self = [super init];
    if (self) {
        self.replyToList = [NSMutableArray new];
    }
    return self;
}

-(instancetype)initWithThreadID:(NSInteger)threadID {
    NSString *threadURLString = [[settingCentre quote_thread_host] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long)threadID]];
    __block czzThread *thread;
    [czzURLDownloader sendSynchronousRequestWithURL:[NSURL URLWithString:threadURLString] completionHandler:^(BOOL success, NSData *downloadedData, NSError *error) {
        if (success) {
            NSDictionary *rawJson = [NSJSONSerialization JSONObjectWithData:downloadedData options:NSJSONReadingMutableContainers error:&error];
            if (!error)
                thread = [[czzThread alloc] initWithJSONDictionary:rawJson];
        }
    }];
    
    return thread;
}

-(instancetype)initWithParentID:(NSInteger)parentID {
    NSString *threadURLString = [[[settingCentre thread_content_host] stringByReplacingOccurrencesOfString:kParentID withString:[NSString stringWithFormat:@"%ld", (long)parentID]] stringByReplacingOccurrencesOfString:kPageNumber withString:@"1"];
    __block czzThread *thread;
    [czzURLDownloader sendSynchronousRequestWithURL:[NSURL URLWithString:threadURLString] completionHandler:^(BOOL success, NSData *downloadedData, NSError *error) {
        if (success) {
            NSDictionary *rawJson = [NSJSONSerialization JSONObjectWithData:downloadedData options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                thread = [[czzThread alloc] initWithJSONDictionary:rawJson];
            }
        }
    }];
    
    return thread;
}

/*
 "id": "185934",
 "img": "2015-03-08/54fbc263e793f",
 "ext": ".jpg",
 "now": "2015-03-08(日)11:30:43",
 "userid": "Xr4haKp",
 "name": "ATM",
 "email": "",
 "title": "无标题",
 "content": "A岛安卓客户端领到假饼干的各位请注意：在手机的应用管理里清除A岛客户端的所有应用数据后重新领取饼干即可<br />\r\n现在限时开放领取饼干，请各位在此串回复领取饼干，禁止另开串，谢谢合作。",
 "admin": "1",
 "remainReplys": 2162,
 "replyCount": "2172",
 "replys":
 */

-(id)initWithJSONDictionary:(NSDictionary *)data {
    if ([data isKindOfClass:[NSDictionary class]]) {
        self = [self init];
        @try {
            self.ID = [[data objectForKey:@"id"] integerValue];
            self.parentID = [data objectForKey:@"parent"] ? [[data objectForKey:@"parent"] integerValue] : self.ID;
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            NSString *dateString = [data objectForKey:@"now"];
            dateString = [[NSRegularExpression regularExpressionWithPattern:@"\\(([^\\)]+)\\)"
                                                                    options:NSRegularExpressionCaseInsensitive
                                                                      error:nil] stringByReplacingMatchesInString:dateString options:0 range:NSMakeRange(0, dateString.length) withTemplate:@" "];
            NSDate *postDate = [formatter dateFromString:dateString];
            self.postDateTime = postDate;
            
            self.UID = [self renderHTMLToAttributedString:[data objectForKey:@"userid"]].string;
            self.name = [data objectForKey:@"name"];
            self.email = [data objectForKey:@"email"];
            self.title = [data objectForKey:@"title"];
            self.content = [self renderHTMLToAttributedString:[NSString stringWithString:[data objectForKey:@"content"]]];

            if ([[data objectForKey:@"img"] length] && [[data objectForKey:@"ext"] length]) {
                self.imgSrc = [[data objectForKey:@"img"] stringByAppendingString:[data objectForKey:@"ext"]];
            }
            self.lock = [[data objectForKey:@"lock"] boolValue];
            self.sage = [[data objectForKey:@"sage"] boolValue];
            self.admin = [[data objectForKey:@"admin"] boolValue];
            
            self.responseCount = [[data objectForKey:@"replyCount"] integerValue];
        }
        @catch (NSException *exception) {
            return nil;
        }
    }
    return self;
}

//the incoming xml data should be in this format:
/*
 <model>
 <ResponseCount>4</ResponseCount>
 <ID>1490410</ID>
 <UID>JYLQJ5g7</UID>
 <Name>無名</Name>
 <Email/>
 <Title>無題</Title>
 <Content>请回短信，这个没有攻略的么</Content>
 <ImageSrc/>
 <ThImageSrc/>
 <Lock>false</Lock>
 <Sage>false</Sage>
 <PostDateTime>2013-09-26T23:23:04.58</PostDateTime>
 <UpdateDateTime>2013-09-26T23:42:11.103121</UpdateDateTime>
 */


-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString{
    @try {
        NSString *htmlCopy = [htmlString stringByRemovingPercentEncoding];
        // If cannot remove percent encoding, return the original.
        if (!htmlCopy) {
            htmlCopy = htmlString;
        }
        NSData *htmlData = [htmlCopy dataUsingEncoding:NSUTF8StringEncoding];
        NSAttributedString *renderedString;
        // Make sure renderedString can always be inited properly.
        if (!htmlData) {
            // If there is no data available, just init it with original string or an empty string.
            renderedString = [[NSAttributedString alloc] initWithString:htmlCopy ? htmlCopy : @""];
        } else {
            renderedString = [[NSAttributedString alloc] initWithData: htmlData
                                                              options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                        NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                   documentAttributes:nil error:nil];
        }
        
        //fine all >> quoted text
        NSArray *segments = [renderedString.string componentsSeparatedByString:@">>"];
        if (segments.count > 1) {
            for (NSString* segment in segments) {
                NSString *processedSeg = [segment stringByReplacingOccurrencesOfString:@"No." withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, segment.length)];
                NSInteger refNumber  = processedSeg.integerValue;
                if (refNumber != 0) {
                    if (!self.replyToList)
                        self.replyToList = [NSMutableArray new];
                    [self.replyToList addObject:[NSNumber numberWithInteger:refNumber]];
                }
            }
        }
        
        return renderedString;
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
    return [[NSAttributedString alloc] initWithString:htmlString.length ? htmlString : @""];
}

#pragma mark - Accessor

// thImgSrc is no longer in use, return self.imgSrc in its getter instead.
- (NSString *)thImgSrc {
    return self.imgSrc;
}

- (NSString *)contentSummary {
    NSString *summary = @"";
    if (self.content.string.length) {
        summary = self.content.string;
    } else if (self.title.length) {
        summary = self.title;
    }
    // Shrink the length of summary down to 15 characters.
    if (summary.length > 15) {
        summary = [NSString stringWithFormat:@"%@...", [summary substringToIndex:12]];
    }
    return summary;
}

#pragma mark - convert to czzWKThread object

-(czzWKThread *)watchKitThread {
    czzWKThread *wkThread = [czzWKThread new];
    wkThread.ID = self.ID;
    wkThread.title = self.title;
    wkThread.name = self.UID;
    wkThread.content = self.content.string;
    wkThread.postDate = self.postDateTime;
    wkThread.thumbnailFile = self.thImgSrc;
    wkThread.imageFile = self.imgSrc;
    
    return wkThread;
}

#pragma mark - isEqual and Hash function, for this class to be used within a NSSet
-(BOOL)isEqual:(id)object{
    if ([object isKindOfClass:self.class]) {
        if ([object hash] == self.hash){
            return YES;
        }
    }
    return NO;
}

//the hash for a thread is its UID and its ID and its post date time
-(NSUInteger)hash{
    return self.UID.hash + self.ID + [self.postDateTime descriptionWithLocale:[NSLocale systemLocale]].hash;
}

#pragma mark - encoding and decoding functions
-(void)encodeWithCoder:(NSCoder*)encoder{
    [encoder encodeInteger:self.responseCount forKey:@"responseCount"];
    [encoder encodeInteger:self.ID forKey:@"ID"];
    [encoder encodeObject:self.UID forKey:@"UID"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.content forKey:@"content"];
    [encoder encodeObject:self.imgSrc forKey:@"imgSrc"];
    [encoder encodeObject:self.thImgSrc forKey:@"thImgSrc"];
    [encoder encodeBool:self.lock forKey:@"lock"];
    [encoder encodeBool:self.sage forKey:@"sage"];
    [encoder encodeBool:self.admin forKey:@"admin"];
    [encoder encodeObject:self.postDateTime forKey:@"postDateTime"];
    [encoder encodeObject:self.updateDateTime forKey:@"updateDateTime"];
    [encoder encodeObject:self.replyToList forKey:@"replyToList"];
}

-(id)initWithCoder:(NSCoder*)decoder{
    self = [czzThread new];
    if (self){
        @try {
            self.responseCount = [decoder decodeIntegerForKey:@"responseCount"];
            self.ID = [decoder decodeIntegerForKey:@"ID"];
            self.UID = [decoder decodeObjectForKey:@"UID"];
            self.name = [decoder decodeObjectForKey:@"name"];
            self.email = [decoder decodeObjectForKey:@"email"];
            self.title = [decoder decodeObjectForKey:@"title"];
            self.content = [decoder decodeObjectForKey:@"content"];
            self.imgSrc = [decoder decodeObjectForKey:@"imgSrc"];
            self.thImgSrc = [decoder decodeObjectForKey:@"thImgSrc"];
            self.lock = [decoder decodeBoolForKey:@"lock"];
            self.sage = [decoder decodeBoolForKey:@"sage"];
            self.admin = [decoder decodeBoolForKey:@"admin"];
            self.postDateTime = [decoder decodeObjectForKey:@"postDateTime"];
            self.updateDateTime = [decoder decodeObjectForKey:@"updateDateTime"];
            self.replyToList = [decoder decodeObjectForKey:@"replyToList"];
        } @catch (NSException *exception) {
            DLog(@"%@", exception);
            self.responseCount = 0;
            self.ID = 0;
            self.UID = @"0";
            self.name = @"0";
            self.email = @"0";
            self.title = @"0";
            self.content = [[NSAttributedString alloc] initWithString:@"0"];
            self.imgSrc = @"";
            self.thImgSrc = @"";
            self.lock = false;
            self.sage = false;
            self.admin = false;
            self.postDateTime = [NSDate new];
            self.updateDateTime = [NSDate new];
            self.replyToList = [NSMutableArray new];
        }
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"ID:%ld - UID:%@ - content:%@ - img:%@", (long) self.ID, self.UID, self.content.string, self.imgSrc];
}
@end
