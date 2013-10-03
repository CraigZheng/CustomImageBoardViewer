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
        if ([child.name isEqualToString:@"ID"]){
            self.ID = [child.value integerValue];
        }
        if ([child.name isEqualToString:@"UID"]){
            self.UID = child.value;
        }
        if ([child.name isEqualToString:@"Name"]){
            self.name = child.value;
        }
        if ([child.name isEqualToString:@"Email"]){
            self.email = child.value;
        }
        if ([child.name isEqualToString:@"Title"]){
            self.title = child.value;
        }
        if ([child.name isEqualToString:@"Content"]){
            NSString *stringToParse = child.value;
            self.content = [self parseHTMLAttributes:stringToParse];
        }
        if ([child.name isEqualToString:@"ImageSrc"]){
            self.imgScr = child.value;
        }
        if ([child.name isEqualToString:@"ThImageSrc"]){
            self.thImgSrc = child.value;
        }
        if ([child.name isEqualToString:@"Lock"]){
            self.lock = [child.value boolValue];
        }
        if ([child.name isEqualToString:@"Sage"]){
            self.sage = [child.value boolValue];
        }
        if ([child.name isEqualToString:@"PostDateTime"]){
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'hh':'mm':'ss'.'fff"];
            NSDate *date = [formatter dateFromString:child.value];

            self.postDateTime = date;
        }
    }
}

-(NSAttributedString*)parseHTMLAttributes:(NSString*)stringToParse{
    stringToParse = [stringToParse gtm_stringByUnescapingFromHTML];
    //get rip of <br/> tag
    stringToParse = [stringToParse stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    
    //find my replyTo list
    return [[NSAttributedString alloc] initWithAttributedString:[self removeFontTags:stringToParse]];
}

-(NSAttributedString*)removeFontTags:(NSString*)str{
    //UIColor *quoteColor = [UIColor colorWithRed:(120.0/255.0) green:(153.0/255.0) blue:(34.0/255.0) alpha:1.0];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str];
    if (str) {
        NSRange frontTagBegin = [str rangeOfString:@"<font"];
        //while there are still <font> tags
        while (frontTagBegin.location != NSNotFound) {
            NSRange frontTagEnd = [str rangeOfString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(frontTagBegin.location, str.length - frontTagBegin.location)];
            str = [str stringByReplacingCharactersInRange:NSMakeRange(frontTagBegin.location, (frontTagEnd.location - frontTagBegin.location + 1)) withString:@""];
            //remove the </font> tag
            str = [str stringByReplacingOccurrencesOfString:@"</font>" withString:@""];
            
            attributedString = [[NSMutableAttributedString alloc] initWithString:str];
            frontTagBegin = [str rangeOfString:@"<font"];

        }
    }
    
    return attributedString;
}

#pragma isEqual and Hash function, for this class to be used within a NSSet
-(BOOL)isEqual:(id)object{
    if ([object isKindOfClass:self.class]) {
        if ([object hash] == self.hash){
            return YES;
        }
    }
    return NO;
}
-(NSUInteger)hash{
    return self.UID.hash * self.ID * self.content.string.hash;
}
@end
