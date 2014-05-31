//
//  CustomImageBoardViewerTests.m
//  CustomImageBoardViewerTests
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "czzNotification.h"

@interface CustomImageBoardViewerTests : XCTestCase

@end

@implementation CustomImageBoardViewerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    NSString *xmlString = @"<result><success>true</success><status>200</status><model><ArrayOfForumGroup><ForumGroup><Area>综合</Area><ForumNames><string>综合版1</string><string>欢乐恶搞</string> <string>数码</string> <string>速报</string> <string>推理</string><string>都市怪谈</string><string>技术宅</string><string>询问2</string><string>料理</string><string>貓版</string><string>音乐</string><string>体育</string><string>军武</string><string>模型</string><string>考试</string><string>WIKI</string></ForumNames></ForumGroup><ForumGroup><Area>二次元</Area><ForumNames><string>动画</string><string>漫画</string><string>轻小说</string><string>推理</string><string>小说</string><string>二次创作</string><string>VOCALOID</string><string>东方Project</string></ForumNames></ForumGroup><ForumGroup><Area>游戏</Area> <ForumNames><string>游戏</string><string>沃土</string><string>DNF</string><string>EVE</string><string>战争雷霆</string><string>扩散性百万亚瑟王</string><string>信喵之野望</string><string>LOL</string><string>DOTA</string><string>Minecraft</string><string>MUG</string><string>MUGEN</string><string>WOT</string><string>WOW</string><string>卡牌桌游</string><string>炉石传说</string><string>怪物猎人</string><string>索尼</string><string>任天堂</string><string>口袋妖怪</string><string>AC大逃杀</string></ForumNames></ForumGroup><ForumGroup><Area>三次元</Area><ForumNames><string>AKB</string><string>COSPLAY</string><string>影视</string><string>摄影</string><string>声优</string></ForumNames></ForumGroup><ForumGroup><Area>管理</Area><ForumNames><string>值班室</string></ForumNames></ForumGroup></ArrayOfForumGroup></model></result>";
    
    NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
    czzNotification *notification = [[czzNotification alloc] initWithXMLData:data];
    XCTAssertNotEqual(notification, [czzNotification new], @"equal!");
    
}

@end
