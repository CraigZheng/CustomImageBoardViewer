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
#import "czzImageCentre.h"
#import "NSString+HTML.h"
#import "czzSettingsCentre.h"

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
    NSString *target = [[[settingCentre thread_content_host] stringByReplacingOccurrencesOfString:kThreadID withString:[NSString stringWithFormat:@"%ld", (long)threadID]] stringByReplacingOccurrencesOfString:kPageNumber withString:@"1"];
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:target]] returningResponse:&response error:nil];
    if (data)
    {
        NSError *error;
        NSDictionary *rawJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!error) {
            czzThread *resultThread = [[czzThread alloc] initWithJSONDictionaryV2:rawJson];
            return resultThread;
        }
    }
    
    return nil;
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
/*
 new format
 */
-(instancetype)initWithJSONDictionaryV2:(NSDictionary *)data {
    self = [super init];
    if (self) {
        @try {
            self.ID = [[self readFromJsonDictionary:data withName:@"id"] integerValue];
            //images
            NSString *imgString = [self readFromJsonDictionary:data withName:@"img"];
            if (imgString.length) {
                self.imgSrc = [imgString stringByAppendingString:[self readFromJsonDictionary:data withName:@"ext"]];

                self.thImgSrc = [[imgString stringByAppendingString:@"_t"] stringByAppendingString:[self readFromJsonDictionary:data withName:@"ext"]];                
            }
            //date -  "now": "2015-03-08(日)11:30:43",
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *dateTimeString = [[[self readFromJsonDictionary:data withName:@"now"] componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
            self.postDateTime = [formatter dateFromString:dateTimeString];

            //various contents
            if ([[self readFromJsonDictionary:data withName:@"admin"] boolValue]) {
                self.UID = [[NSAttributedString alloc] initWithString:[self readFromJsonDictionary:data withName:@"name"] attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
            } else
                self.UID = [[NSAttributedString alloc] initWithString:[self readFromJsonDictionary:data withName:@"userid"]];
            self.email = [self readFromJsonDictionary:data withName:@"email"];
            self.title = [self readFromJsonDictionary:data withName:@"title"];
            self.content = [self renderHTMLToAttributedString:[self readFromJsonDictionary:data withName:@"content"]];
            self.responseCount = [[self readFromJsonDictionary:data withName:@"replyCount"] integerValue];
            //check contents
            [self checkBlacklist];
            [self checkRemoteConfiguration];
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
            return nil;
        }
    }
    return self;
}

-(id)initWithJSONDictionary:(NSDictionary *)data {
    self = [self init];
    if (self) {
        @try {
            self.ID = [[data objectForKey:@"id"] integerValue];
            
            self.parentID = [[data objectForKey:@"parent"] integerValue] != 0 ? [[data objectForKey:@"parent"] integerValue] : self.ID;

            self.postDateTime = [NSDate dateWithTimeIntervalSince1970:[[data objectForKey:@"createdAt"] doubleValue] / 1000.0];
            self.updateDateTime = [NSDate dateWithTimeIntervalSince1970:[[data objectForKey:@"updatedAt"] doubleValue] / 1000.0];
            //UID might have different colour, but I am setting any colour other than default to red at the moment
            NSString *uidString = [data objectForKey:@"uid"];
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[self renderHTMLToAttributedString:uidString].string];
            //if the given string contains keyword "color", then render it red to indicate its important
            if ([uidString.lowercaseString rangeOfString:@"color"].location != NSNotFound) {
                [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, attrString.length)];
            }
            self.UID = attrString;
            
            self.name = [data objectForKey:@"name"];
            self.email = [data objectForKey:@"email"];
            self.title = [data objectForKey:@"title"];

            //content
            if (self.title.length > 10) {
                NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" * %@ * \n\n", self.title] attributes:nil];
                [content appendAttributedString:[self renderHTMLToAttributedString:[data objectForKey:@"content"]]];
                self.content = content;
            }
            else
                self.content = [self renderHTMLToAttributedString:[NSString stringWithString:[data objectForKey:@"content"]]];
            
            self.imgSrc = [data objectForKey:@"image"];
            self.thImgSrc = [data objectForKey:@"thumb"];
            self.lock = [[data objectForKey:@"lock"] boolValue];
            self.sage = [[data objectForKey:@"sage"] boolValue];
            self.responseCount = [[data objectForKey:@"replyCount"] integerValue];
            [self checkBlacklist];
            [self checkRemoteConfiguration];

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

-(void)checkBlacklist {
    if (![settingCentre shouldEnableBlacklistFiltering])
        return;
    //consor contents
    czzBlacklistEntity *blacklistEntity = [[czzBlacklist sharedInstance] blacklistEntityForThreadID:self.ID];
    if (blacklistEntity){
        //assign the blacklist value to this thread
        self.harmful = blacklistEntity.harmful;
        self.blockContent = blacklistEntity.content;
        if (self.blockContent)
            self.content = [[NSMutableAttributedString alloc] initWithString:@"已屏蔽"];
        self.blockImage = blacklistEntity.image;
        if (self.blockImage){
            self.imgSrc = nil;
            self.thImgSrc = nil;
        }
        self.blockAll = blacklistEntity.block;
        if (self.blockAll)
        {
            self.content = [[NSMutableAttributedString alloc] initWithString:@"已屏蔽"];
            self.imgSrc = nil;
            self.thImgSrc = nil;
        }
    }

}

-(void)checkRemoteConfiguration {
    if (![settingCentre shouldDisplayThumbnail]) {
        self.thImgSrc = nil;
    }
    if (![settingCentre shouldDisplayImage]) {
        self.imgSrc = nil;
    }
    if (![settingCentre shouldDisplayContent]) {
        self.content = [[NSMutableAttributedString alloc] initWithString:@"已屏蔽"];
    }
}

-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString{
    htmlString = [htmlString stringByDecodingHTMLEntities];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&nbsp;ﾟ" withString:@"　ﾟ"];
//    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&#180" withString:@"´"];

    NSAttributedString *renderedString = [[NSAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUTF8StringEncoding]
                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                 documentAttributes:nil error:nil];
    
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
    return self.UID.hash + self.ID + self.postDateTime.hash;
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
    [encoder encodeObject:self.postDateTime forKey:@"postDateTime"];
    [encoder encodeObject:self.updateDateTime forKey:@"updateDateTime"];
    [encoder encodeBool:self.isParent forKey:@"isParent"];
    [encoder encodeObject:self.replyToList forKey:@"replyToList"];
    [encoder encodeBool:self.harmful forKey:@"harmful"];
    [encoder encodeBool:self.blockContent forKey:@"blockContent"];
    [encoder encodeBool:self.blockImage forKey:@"blockImage"];
    [encoder encodeBool:self.blockAll forKey:@"blockAll"];
    [encoder encodeObject:self.forum forKey:@"forum"];
}

-(id)initWithCoder:(NSCoder*)decoder{
    self = [czzThread new];
    if (self){
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
        self.postDateTime = [decoder decodeObjectForKey:@"postDateTime"];
        self.updateDateTime = [decoder decodeObjectForKey:@"updateDateTime"];
        self.isParent = [decoder decodeBoolForKey:@"isParent"];
        self.replyToList = [decoder decodeObjectForKey:@"replyToList"];
        self.harmful = [decoder decodeBoolForKey:@"harmful"];
        self.blockContent = [decoder decodeBoolForKey:@"blockContent"];
        self.blockImage = [decoder decodeBoolForKey:@"blockImage"];
        self.blockAll = [decoder decodeBoolForKey:@"blockAll"];
        self.forum = [decoder decodeObjectForKey:@"forum"];
        //blacklist info might be updated when this thread is not in the memory
        //consor contents
        czzBlacklistEntity *blacklistEntity = [[czzBlacklist sharedInstance] blacklistEntityForThreadID:self.ID];
        if (blacklistEntity){
            //assign the blacklist value to this thread
            self.harmful = blacklistEntity.harmful;
            self.blockContent = blacklistEntity.content;
            if (self.blockContent)
                self.content = [[NSMutableAttributedString alloc] initWithString:@"已屏蔽"];
            self.blockImage = blacklistEntity.image;
            if (self.blockImage){
                self.imgSrc = nil;
                self.thImgSrc = nil;
            }
            self.blockAll = blacklistEntity.block;
            if (self.blockAll)
            {
                self.content = [[NSMutableAttributedString alloc] initWithString:@"已屏蔽"];
                self.imgSrc = nil;
                self.thImgSrc = nil;
            }
        }
        
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"ID:%ld - UID:%@ - content:%@ - img:%@", (long) self.ID, self.UID.string, self.content.string, self.imgSrc];
}
@end
