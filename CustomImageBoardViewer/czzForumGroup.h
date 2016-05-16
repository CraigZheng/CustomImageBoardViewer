//
//  czzForumGroup.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzForumGroup : NSObject
@property (strong, nonatomic) NSString *area;
@property NSMutableArray *forums;

+ (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/*
 {
 "id": "6",
 "sort": "6",
 "name": "管理",
 "status": "n",
 "forums": [
 {
 "id": "18",
 "fgroup": "6",
 "sort": "1",
 "name": "值班室",
 "showName": "",
 "msg": "<p>&bull;本版发文间隔为15秒。<br />\r\n&bull;请在此举报不良内容，并附上串地址以及发言者ID。如果是回复串，请附上&ldquo;回应&rdquo;链接的地址，格式为&gt;&gt;No.串ID或&gt;&gt;No.回复ID<br />\r\n&bull;主站相关问题反馈、建议请在这里留言<br />\r\n&bull;已处理的举报将锁定。</p>\r\n",
 "interval": "15",
 "createdAt": "2011-09-30 23:55:20",
 "updateAt": "2015-07-26 15:39:24",
 "status": "n"
 }
 ]
 }
 */
@end
