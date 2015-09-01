//
//  czzThreadData.m
//  
//
//  Created by Craig Zheng on 27/06/2015.
//
//

#import "czzThreadData.h"
#import "czzThread.h"

@implementation czzThreadData

@dynamic blockAll;
@dynamic blockContent;
@dynamic blockImage;
@dynamic content;
@dynamic email;
@dynamic harmful;
@dynamic threadID;
@dynamic imgSrc;
@dynamic isParent;
@dynamic lock;
@dynamic name;
@dynamic parentID;
@dynamic postDateTime;
@dynamic replyToList;
@dynamic responseCount;
@dynamic sage;
@dynamic thImgSrc;
@dynamic title;
@dynamic uid;
@dynamic updateDateTime;


-(BOOL)copyPropertiesFromThread:(czzThread *)thread {
    if (!thread || ![thread isKindOfClass:[czzThread class]]) {
        return NO;
    }
    
    self.blockAll = @(thread.blockAll);
    self.blockContent = @(thread.blockContent);
    self.blockImage = @(thread.blockImage);
    self.content = thread.content.string;
    self.email = thread.email;
    self.harmful = @(thread.harmful);
    self.threadID = @(thread.ID);
    self.imgSrc = thread.imgSrc;
    self.thImgSrc = thread.thImgSrc;
    self.isParent = @(thread.isParent);
    self.lock = @(thread.lock);
    self.name = thread.name;
    self.parentID = @(thread.parentID);
    self.postDateTime = thread.postDateTime;
    self.replyToList = [thread.replyToList description];
    self.responseCount = @(thread.responseCount);
    self.sage = @(thread.sage);
    self.thImgSrc = thread.thImgSrc;
    self.title = thread.title;
    self.uid = @(thread.UID.string.floatValue);
    self.updateDateTime = thread.updateDateTime;
    
    return YES;
}

@end
