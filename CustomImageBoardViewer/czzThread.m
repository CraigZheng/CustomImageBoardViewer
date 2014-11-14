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
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzThread
@synthesize settingsCentre;

-(id)init {
    self = [super init];
    if (self) {
        settingsCentre = [czzSettingsCentre sharedInstance];
        self.replyToList = [NSMutableArray new];
    }
    return self;
}

-(id)initWithJSONDictionary:(NSDictionary *)data {
    self = [self init];
    if (self) {
        @try {
            self.ID = [[data objectForKey:@"id"] integerValue];
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
//                self.content = [self renderHTMLToAttributedString:[NSString stringWithFormat:@" * %@ * \n\n%@", self.title, [data objectForKey:@"content"]]];
            }
            else
                self.content = [self renderHTMLToAttributedString:[NSString stringWithString:[data objectForKey:@"content"]]];
            
            self.imgSrc = [data objectForKey:@"image"];
            self.thImgSrc = [data objectForKey:@"thumb"];
            self.lock = [[data objectForKey:@"lock"] boolValue];
            self.sage = [[data objectForKey:@"sage"] boolValue];
            self.responseCount = [[data objectForKey:@"replyCount"] integerValue];
            
            [self checkBlacklist];
            [self checkImageURLs];
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
    if (!settingsCentre.shouldEnableBlacklistFiltering)
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

-(void)checkImageURLs {
    if (self.thImgSrc.length != 0){
        NSString *targetImgURL = [settingsCentre.thumbnail_host stringByAppendingPathComponent:self.thImgSrc];
        //if is set to show image
        if (settingsCentre.userDefShouldDisplayThumbnail || !settingsCentre.shouldDisplayThumbnail){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[czzImageCentre sharedInstance] downloadThumbnailWithURL:targetImgURL isCompletedURL:YES];
            });
        } else {
            self.thImgSrc = nil;
        }

    }
}

-(void)checkRemoteConfiguration {
    if (!settingsCentre.shouldDisplayThumbnail) {
        self.thImgSrc = nil;
    }
    if (!settingsCentre.shouldDisplayImage) {
        self.imgSrc = nil;
    }
    if (!settingsCentre.shouldDisplayContent) {
        self.content = [[NSMutableAttributedString alloc] initWithString:@"已屏蔽"];
    }
}

-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString{
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&nbsp;ﾟ" withString:@"　ﾟ"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&#180" withString:@"´"];

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
            if (refNumber != 0)
                [self.replyToList addObject:[NSNumber numberWithInteger:refNumber]];
        }
    }

    return renderedString;

    //old methods
    htmlString = [htmlString gtm_stringByUnescapingFromHTML];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&#180" withString:@"´"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&nbsp;ﾟ" withString:@"　ﾟ"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];

    NSMutableAttributedString *attributedHtmlString = [[NSMutableAttributedString alloc] initWithString:htmlString];
    NSRange r;
    //remove everything between < and >
    NSMutableArray *pendingTextToRender = [NSMutableArray new];
    UIColor *fontColor = [UIColor blackColor];
    while ((r = [attributedHtmlString.string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        NSRange endTagRange;
        NSString *tagString = [attributedHtmlString.string substringWithRange:r];
        if ([tagString rangeOfString:@"<font"].location != NSNotFound && (endTagRange = [attributedHtmlString.string rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, attributedHtmlString.length - r.length - r.location)]).location != NSNotFound) {
//            NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.length);
            NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
            NSString *textWithTag = [attributedHtmlString.string substringWithRange:textRange];
            if (textWithTag.length > 0) {
                [pendingTextToRender addObject:textWithTag];
            }
            if ([fontColor isEqual:[UIColor blackColor]]) {
                NSString *colorString;
                @try {
                    if ([tagString rangeOfString:@"#"].location != NSNotFound)
                        colorString = [tagString substringWithRange:NSMakeRange([tagString rangeOfString:@"#"].location, 7)];
                    else
                        colorString = @"";
                }
                @catch (NSException *exception) {
                    NSLog(@"%@", exception);
                    colorString = @"";
                }
                fontColor = [self colorForHex:colorString];
            }
            //CLICKABLE CONTENT
            if ([textWithTag rangeOfString:@">>"].location != NSNotFound){
                NSString *newString = [[textWithTag componentsSeparatedByCharactersInSet:
                                        [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                       componentsJoinedByString:@""];
                if ([newString integerValue] != 0)
                    [self.replyToList addObject:[NSNumber numberWithInteger:[newString integerValue]]];
            }

        }
        [attributedHtmlString deleteCharactersInRange:r];
    }
    
    //colour - adjust to nighty mode
    [attributedHtmlString setAttributes:@{NSForegroundColorAttributeName: settingsCentre.contentTextColour} range:NSMakeRange(0, attributedHtmlString.length)];
    for (NSString *pendingText in pendingTextToRender) {
        NSRange textRange = [attributedHtmlString.string rangeOfString:pendingText];
        [attributedHtmlString setAttributes:@{NSForegroundColorAttributeName: fontColor} range:textRange];
    }
//    return fragments;
    return attributedHtmlString;
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
    return self.UID.hash * self.ID * self.postDateTime.hash;
}


#pragma mark - hex to UIColor, copied from internet
- (UIColor *) colorForHex:(NSString *)hexColor {
    @try {
        hexColor = [[hexColor stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]
                     ] uppercaseString];
        
        // String should be 6 or 7 characters if it includes '#'
        if ([hexColor length] < 6)
            return [UIColor blackColor];
        
        // strip # if it appears
        if ([hexColor hasPrefix:@"#"])
            hexColor = [hexColor substringFromIndex:1];
        
        // if the value isn't 6 characters at this point return
        // the color black
        if ([hexColor length] != 6)
            return [UIColor blackColor];
        
        // Separate into r, g, b substrings
        NSRange range;
        range.location = 0;
        range.length = 2;
        
        NSString *rString = [hexColor substringWithRange:range];
        
        range.location = 2;
        NSString *gString = [hexColor substringWithRange:range];
        
        range.location = 4;
        NSString *bString = [hexColor substringWithRange:range];
        
        // Scan values
        unsigned int r, g, b;
        [[NSScanner scannerWithString:rString] scanHexInt:&r];
        [[NSScanner scannerWithString:gString] scanHexInt:&g];
        [[NSScanner scannerWithString:bString] scanHexInt:&b];
        
        return [UIColor colorWithRed:((float) r / 255.0f)
                               green:((float) g / 255.0f)
                                blue:((float) b / 255.0f)
                               alpha:1.0f];
    }
    @catch (NSException *exception) {
        NSLog(@"exception");
    }
    @finally {
        
    }
    return [UIColor blackColor];
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
