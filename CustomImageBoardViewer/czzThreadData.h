//
//  czzThreadData.h
//  
//
//  Created by Craig Zheng on 27/06/2015.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class czzThread;
@interface czzThreadData : NSManagedObject

@property (nonatomic, retain) NSNumber * blockAll;
@property (nonatomic, retain) NSNumber * blockContent;
@property (nonatomic, retain) NSNumber * blockImage;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * harmful;
@property (nonatomic, retain) NSNumber * threadID;
@property (nonatomic, retain) NSString * imgSrc;
@property (nonatomic, retain) NSNumber * isParent;
@property (nonatomic, retain) NSNumber * lock;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * parentID;
@property (nonatomic, retain) NSDate * postDateTime;
@property (nonatomic, retain) NSString * replyToList;
@property (nonatomic, retain) NSNumber * responseCount;
@property (nonatomic, retain) NSNumber * sage;
@property (nonatomic, retain) NSString * thImgSrc;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSDate * updateDateTime;

-(BOOL)copyPropertiesFromThread:(czzThread *)thread;
@end
