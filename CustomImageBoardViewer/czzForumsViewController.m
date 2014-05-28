//
//  czzForumsViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumsViewController.h"
#import "czzThread.h"
#import "czzXMLDownloader.h"
#import "czzForumGroup.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"
#import "czzAppDelegate.h"

@interface czzForumsViewController () <czzXMLDownloaderDelegate>
@property czzXMLDownloader *xmlDownloader;
@property NSMutableArray *forumGroups;
@property BOOL failedToConnect;
@end

@implementation czzForumsViewController
@synthesize xmlDownloader;
@synthesize forumsTableView;
@synthesize forumGroups;
@synthesize failedToConnect;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    forumGroups = [NSMutableArray new];
    [self refreshForums];
}

-(void)refreshForums{
    failedToConnect = NO;
    if (xmlDownloader)
        [xmlDownloader stop];
    //NSString *forumString = @"http://civ.my-realm.com/forums.xml";
    NSString *forumString = [[czzAppDelegate sharedAppDelegate].myhost stringByAppendingPathComponent:@"forums.xml"];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:forumString] delegate:self startNow:YES];
    [self.view makeToastActivity];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

#pragma UITableView datasouce
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (failedToConnect)
        return 1;
    return forumGroups.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (failedToConnect)
        return 1;
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:section];
    return forumGroup.forumNames.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (failedToConnect || forumGroups.count == 0){
        return @" ";
    }
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:section];
    return forumGroup.area;
    
}

#pragma UITableView delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cell_identifier = @"forum_cell_identifier";
    if (failedToConnect){
        return [tableView dequeueReusableCellWithIdentifier:@"no_service_cell_identifier"];
    }
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell){
        UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
        [titleLabel setText:[forumGroup.forumNames objectAtIndex:indexPath.row]];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (failedToConnect){
        [self refreshForums];
        return;
    }
    if (forumGroups.count == 0)
        return;
    czzForumGroup *forumGroup = [forumGroups objectAtIndex:indexPath.section];
    NSString *forumName = [forumGroup.forumNames objectAtIndex:indexPath.row];
    [self.viewDeckController toggleLeftViewAnimated:YES];
    //POST a local notification to inform other view controllers that a new forum is picked
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setObject:forumName forKey:@"ForumName"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ForumNamePicked" object:self userInfo:userInfo];
    
}

#pragma czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    if (successed){
        forumGroups = [NSMutableArray new];
        //parse the return XML object
        NSError *error;
        SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
        if (error){
            NSLog(@"%@", error);
            return;
        }
        NSArray *children = [xmlDoc.root children];
        for (SMXMLElement *child in children){
            //parse the result
            if ([child.name isEqualToString:@"status"]){
                NSInteger status = [child.value integerValue];
                if (status != 200){
                    [self.view makeToast:@"网络错误：无法接上服务器" duration:1.5 position:@"bottom" image:[UIImage imageNamed:@"warning"]];
                    break;
                }
            }
            //parse the model
            if ([child.name isEqualToString:@"model"]){
                [self parseModel:child];
            }
        }
    }
    [self.view hideToastActivity];
    if (forumGroups.count <= 0)
        failedToConnect = YES;
    [forumsTableView reloadData];
}

#pragma XML parser
-(void)parseModel:(SMXMLElement*)model{
    for (SMXMLElement *child in model.children) {
        if ([child.name isEqualToString:@"ArrayOfForumGroup"]){
            for (SMXMLElement *forumGroup in child.children) {
                [self parseForumGroup:forumGroup];
            }
        }
    }
}

-(void)parseForumGroup:(SMXMLElement*)forumGroup{
    czzForumGroup *newForumGroup = [czzForumGroup new];
    for (SMXMLElement *child in forumGroup.children) {
        if ([child.name isEqualToString:@"Area"]){
            newForumGroup.area = child.value;
        } else if ([child.name isEqualToString:@"ForumNames"]){
            //each children would be a name of a forum
            for (SMXMLElement *forum in child.children) {
                [newForumGroup.forumNames addObject:forum.value];
            }
        }
    }
    [forumGroups addObject:newForumGroup];
}


@end
