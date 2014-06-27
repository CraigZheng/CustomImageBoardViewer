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

@implementation czzThread

-(id)initWithSMXMLElement:(SMXMLElement *)xmlElement{
    self = [super init];
    if (self){
        //parse the incoming xml data
        self.replyToList = [NSMutableArray new];
        [self acceptXMLElement:xmlElement];
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
-(void)acceptXMLElement:(SMXMLElement*)xmlElement{
    for (SMXMLElement *child in xmlElement.children) {
        if ([child.name isEqualToString:@"ResponseCount"]){
            self.responseCount = [child.value integerValue];
        }
        else if ([child.name isEqualToString:@"ID"]){
            self.ID = [child.value integerValue];
        }
        else if ([child.name isEqualToString:@"UID"]){
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithAttributedString:[self parseHTMLAttributes:child.value]];
            //manually set colour
            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:153.0f/255.0f green:102.0f/255.0f blue:51.0f/255.0f alpha:1.0f] range:NSMakeRange(0, attrString.length)];
            //if the given string contains keyword "color", then render it red to indicate its important
            if ([child.value.lowercaseString rangeOfString:@"color"].location != NSNotFound) {
                [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, attrString.length)];
            }
            [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10] range:NSMakeRange(0, attrString.length)];

            self.UID = attrString;
        }
        else if ([child.name isEqualToString:@"Name"]){
            self.name = [self parseHTMLAttributes:child.value].string;
        }
        else if ([child.name isEqualToString:@"Email"]){
            self.email = [self parseHTMLAttributes:child.value].string;
        }
        else if ([child.name isEqualToString:@"Title"]){
            self.title = [self parseHTMLAttributes:child.value].string;
        }
        else if ([child.name isEqualToString:@"Content"]){
//            self.content = [self prepareHTMLForFragments:[NSString stringWithString:child.value]];
            //if title has more than 10 chinese words, it will be too long to fit in the title bar
            //therefore we put it at the beginning of the content
            if (self.title.length > 10)
                self.content = [self prepareHTMLForFragments:[NSString stringWithFormat:@" * %@ * \n\n%@", self.title, child.value]];
            else
                self.content = [self prepareHTMLForFragments:[NSString stringWithString:child.value]];

        }
        else if ([child.name isEqualToString:@"ImageSrc"]){
            self.imgSrc = child.value;
        }
        else if ([child.name isEqualToString:@"ThImageSrc"]){
            self.thImgSrc = child.value;
        }
        else if ([child.name isEqualToString:@"Lock"]){
            self.lock = [child.value boolValue];
        }
        else if ([child.name isEqualToString:@"Sage"]){
            self.sage = [child.value boolValue];
        }
        else if ([child.name isEqualToString:@"PostDateTime"]){
            NSString *timestamp = [child.value stringByDeletingPathExtension];
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            NSDate *date = [formatter dateFromString:timestamp];

            self.postDateTime = date;
        }
    }
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
    
    if (self.thImgSrc.length != 0){
        //if is set to show image is presented
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldDownloadThumbnail"]){
            //if its set to YES
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldDownloadThumbnail"]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[czzImageCentre sharedInstance] downloadThumbnailWithURL:self.thImgSrc isCompletedURL:NO];
                });
            } else {
                self.thImgSrc = nil;
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[czzImageCentre sharedInstance] downloadThumbnailWithURL:self.thImgSrc isCompletedURL:NO];
            });
        }
    }
}

-(NSAttributedString*)parseHTMLAttributes:(NSString*)stringToParse{
    if (!stringToParse)
        return nil;
    //get rip of HTML tags
    stringToParse = [stringToParse gtm_stringByUnescapingFromHTML];
    //get rip of <br/> tag
    stringToParse = [stringToParse stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    //manually pick up some quotes that can not be spotted by machine
    stringToParse = [stringToParse stringByReplacingOccurrencesOfString:@"&#180" withString:@"´"];
    
    return [self removeFontTags:stringToParse];
}

-(NSAttributedString*)removeFontTags:(NSString*)str{
    if (!str)
        return nil;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    NSArray *stringComponents = [str componentsSeparatedByString:@"</font>"];
    for (NSString *component in stringComponents) {
        [attributedString appendAttributedString:[self renderFontTags:component]];
    }
    return attributedString;
}

-(NSAttributedString*)prepareHTMLForFragments:(NSString*)htmlString{
    htmlString = [htmlString stringByDecodingHTMLEntities];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&#180" withString:@"´"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    NSMutableAttributedString *attributedHtmlString = [[NSMutableAttributedString alloc] initWithString:htmlString];
    NSRange r;
    //remove everything between < and >
    NSMutableArray *fragments = [NSMutableArray new];
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
                fontColor = [self colorForHex:[tagString substringWithRange:NSMakeRange([tagString rangeOfString:@"#"].location, 7)]];
            }
            //CLICKABLE CONTENT
            if ([textWithTag rangeOfString:@">>"].location != NSNotFound){
                NSString *newString = [[textWithTag componentsSeparatedByCharactersInSet:
                                        [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                       componentsJoinedByString:@""];
                if ([newString integerValue] != 0)
                    [self.replyToList addObject:[NSNumber numberWithInteger:[newString integerValue]]];
                
                //[self.replyToList addObject:renderedStr.string];
            }

            //                NSAttributedString *renderedString = [[NSAttributedString alloc] initWithString:textWithTag attributes:@{NSForegroundColorAttributeName: [UIColor greenColor]}];
        }
        [attributedHtmlString deleteCharactersInRange:r];
        //            attributedHtmlString = [attributedHtmlString stringByReplacingCharactersInRange:r withString:@""];

    }
    for (NSString *pendingText in pendingTextToRender) {
        NSRange textRange = [attributedHtmlString.string rangeOfString:pendingText];
        [attributedHtmlString setAttributes:@{NSForegroundColorAttributeName: fontColor} range:textRange];
    }
    //set the font size and shits
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        /* Device is iPad */
        [attributedHtmlString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18] range:NSMakeRange(0, attributedHtmlString.length)];
    } else {
        [attributedHtmlString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, attributedHtmlString.length)];
    }

//    NSLog(@"%@", attributedHtmlString);
    [fragments addObject:attributedHtmlString];
//    return fragments;
    return attributedHtmlString;
}


/*this function would have 2 routes:
 1: with tags, get rip of <font></font> tag, and render everything in between green
 2: without tags, return as it is
*/
-(NSAttributedString*)renderFontTags:(NSString*)str{
    if (!str) {
        return nil;
    }
    UIColor *quoteColor = [UIColor colorWithRed:(120.0/255.0) green:(153.0/255.0) blue:(34.0/255.0) alpha:1.0];
    NSRange frontTagBegin = [str rangeOfString:@"<font"];
    NSMutableAttributedString *renderedStr;
    if (frontTagBegin.location != NSNotFound) {
        //convert the hex to ui colour first
        NSRange hexRange = [str rangeOfString:@"#"];
        if (hexRange.location != NSNotFound){
            NSString *hexString = [str substringWithRange:NSMakeRange(hexRange.location, 7)];
            quoteColor = [self colorForHex:hexString];
        }
        NSRange frontTagEnd = [str rangeOfString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(frontTagBegin.location, str.length - frontTagBegin.location)];
        //remove the front tag
        str = [str stringByReplacingCharactersInRange:NSMakeRange(frontTagBegin.location, (frontTagEnd.location - frontTagBegin.location + 1)) withString:@""];
        renderedStr = [[NSMutableAttributedString alloc] initWithString:str];
        [renderedStr addAttribute:NSForegroundColorAttributeName value:quoteColor range:NSMakeRange(frontTagBegin.location, str.length - frontTagBegin.location)];
        //CLICKABLE CONTENT
        if ([renderedStr.string rangeOfString:@">>"].location != NSNotFound){
            
            NSString *newString = [[renderedStr.string componentsSeparatedByCharactersInSet:
                                    [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                   componentsJoinedByString:@""];
            if ([newString integerValue] != 0)
                [self.replyToList addObject:[NSNumber numberWithInteger:[newString integerValue]]];
            
            //[self.replyToList addObject:renderedStr.string];
        }
    }
    if (renderedStr == nil) {
        renderedStr = [[NSMutableAttributedString alloc] initWithString:str];
        [renderedStr addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, renderedStr.length)];
    }
    //set the font size and shits
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        /* Device is iPad */
        [renderedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18] range:NSMakeRange(0, renderedStr.length)];
    } else {
        [renderedStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, renderedStr.length)];
    }
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    
    [renderedStr addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, renderedStr.length)];
    return renderedStr;
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
        /*
        for (czzBlacklistEntity *blacklistEntity in [[czzBlacklist sharedInstance] blacklistEntities]) {
            if (blacklistEntity.threadID == self.ID){
         
                 //self.content = [[NSAttributedString alloc] initWithString:@" ** 用户举报的不健康的内容 ** "];
                 //self.imgScr = nil;
         
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
                break;
            }
        }
        */
    }
    return self;
}
@end
