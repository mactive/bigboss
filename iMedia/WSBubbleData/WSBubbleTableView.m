//
//  WSBubbleTableView.m
//  iMedia
//
//  Created by mac on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTableView.h"
#import "WSBubbleData.h"
#import "WSBubbleSectionHeaderTableViewCell.h"
#import "RateViewController.h"
#import "WebViewController.h"
#import "AppDelegate.h"
#import "XMPPFramework.h"
#import "ConversationsController.h"
#import "Conversation.h"
#import "Me.h"

#import "WSBubbleTableViewCell.h"
#import "WSBubbleTextTableViewCell.h"
#import "WSBubbleImageTableViewCell.h"
#import "WSBubbleTemplateATableViewCell.h"
#import "WSBubbleTemplateBTableViewCell.h"
#import "WSBubbleRateTableViewCell.h"
#import "WSBubbleNoticationTableViewCell.h"
#import "ContactDetailController.h"
#import "ProfileMeController.h"

#import "DDLog.h"
#import "ModelHelper.h"
#import "MBProgressHUD.h"
#import "AppNetworkAPIClient.h"
#import "ConvenienceMethods.h"
#import "ServerDataTransformer.h"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif


@implementation WSBubbleTableView

@synthesize snapInterval;
@synthesize showAvatars;
@synthesize bubbleSection;

static NSString *CellText = @"CellText";
static NSString *CellImage = @"CellImage";
static NSString *CellTemplateA = @"CellTemplateA";
static NSString *CellTemplateB = @"CellTemplateB";
static NSString *CellRate = @"CellRate";
static NSString *CellNotification = @"CellNotification";
static NSString *CellSectionHeader = @"CellSectionHeader";


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.dataSource = self;
        self.delegate = self;
        self.snapInterval = 120;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableView section delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (section >= [self.bubbleSection count]) return 1;
    
    return [[self.bubbleSection objectAtIndex:section ] count] ;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.bubbleSection count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableView cell delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WSBubbleData *rowData = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    CGFloat cellHeight = 0.0f;
    if (rowData.type == BubbleTypeMine || rowData.type == BubbleTypeSomeoneElse)
    {
        cellHeight = MAX(rowData.insets.top + rowData.cellHeight + rowData.insets.bottom, 65);
    }else if(rowData.type == BubbleTypeRateview){
        cellHeight = 70.0f;
    }else{
        cellHeight = rowData.insets.top + rowData.cellHeight + rowData.insets.bottom;
    }
    return  cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WSBubbleData *rowData = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    WSBubbleTableViewCell *cell = nil;
    
    if (rowData.type == BubbleTypeMine || rowData.type == BubbleTypeSomeoneElse) {
        if (rowData.msg.bodyType == [NSNumber numberWithInt:MessageBodyTypeImage]) {
            cell = [tableView dequeueReusableCellWithIdentifier:CellImage];
        }else{
            cell = [tableView dequeueReusableCellWithIdentifier:CellText];
        }
    }else if ( rowData.type == BubbleTypeTemplateAview){
        cell = [tableView dequeueReusableCellWithIdentifier:CellTemplateA];
    }else if ( rowData.type == BubbleTypeTemplateBview){
        cell = [tableView dequeueReusableCellWithIdentifier:CellTemplateB];
    }else if ( rowData.type == BubbleTypeRateview){
        cell = [tableView dequeueReusableCellWithIdentifier:CellRate];
    }else if (rowData.type == BubbleTypeNoticationview) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellNotification];
    }else if (rowData.type == BubbleTypeSectionHeader){
        cell = [tableView dequeueReusableCellWithIdentifier:CellSectionHeader];
    }
    
    if (cell == nil) {
        if (rowData.type == BubbleTypeMine || rowData.type == BubbleTypeSomeoneElse) {
            if (rowData.msg.bodyType == [NSNumber numberWithInt:MessageBodyTypeImage]) {
                cell = [[WSBubbleImageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellImage];
            }else{
                cell = [[WSBubbleTextTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellText];
            }
        }else if ( rowData.type == BubbleTypeTemplateAview){
            cell = [[WSBubbleTemplateATableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellTemplateA];
        }else if ( rowData.type == BubbleTypeTemplateBview){
            cell = [[WSBubbleTemplateBTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellTemplateB];
        }else if ( rowData.type == BubbleTypeRateview){
            cell = [[WSBubbleRateTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellRate];
        }else if (rowData.type == BubbleTypeNoticationview) {
            cell = [[WSBubbleNoticationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellNotification];
        }else if (rowData.type == BubbleTypeSectionHeader){
            cell = [[WSBubbleSectionHeaderTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellSectionHeader];
        }
    }
    

    cell.data = rowData;

    return cell;
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - cell did selected
//////////////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Standard bubble
    WSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (data.type == BubbleTypeMine || data.type == BubbleTypeSomeoneElse) {
        if ( [data.msg.from.ePostalID isEqualToString:[self appDelegate].me.ePostalID]) {
            ProfileMeController *controller = [[ProfileMeController alloc] initWithNibName:nil bundle:nil];
            [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
        }else{
            if ([data.msg.from isKindOfClass:[User class]]) {
                ContactDetailController *controller = [[ContactDetailController alloc]initWithNibName:nil bundle:nil];
                controller.user = (User *)data.msg.from;
                controller.GUIDString = [(User *)data.msg.from guid];
                [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
            }
        }
    }
    
    if(data.type == BubbleTypeNoticationview)
    {
        
        User *tt = (User *)data.msg.from;
        [self getDict:[tt ePostalID]];
    }
    
    
    if (data.type == BubbleTypeRateview) {
        RateViewController *rateViewController = [[RateViewController alloc]initWithNibName:nil bundle:nil];
        rateViewController.conversionKey = data.content;

        [[self appDelegate].conversationController.chatDetailController.navigationController presentModalViewController:rateViewController animated:YES];
        
        [[self appDelegate].conversationController.chatDetailController.conversation removeMessagesObject:data.msg];
        data.msg = nil;
        [[self appDelegate].conversationController contentChanged];
    }
    if (data.type == BubbleTypeTemplateAview) {
        
        NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:data.content error:nil];
        NSString* linkString = [[element elementForName:@"link9"] stringValue];
        NSString* titleString = [[element elementForName:@"title1"] stringValue];

        if (StringHasValue(linkString)) {
            WebViewController *controller = [[WebViewController alloc]initWithNibName:nil bundle:nil];
            controller.urlString = linkString;
            
            [[self appDelegate].conversationController.chatDetailController.navigationController setHidesBottomBarWhenPushed:YES];
            [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
            [XFox logEvent:EVENT_READING_ARTICLE withParameters:[NSDictionary dictionaryWithObjectsAndKeys:titleString, @"title", linkString,@"url" nil]];
        }

    }
}


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)getDict:(NSString *)jidString
{
    
    // if the user already exist - then show the user
    User* aUser = [[ModelHelper sharedInstance] findUserWithEPostalID:jidString];
    
    if (aUser != nil && aUser.state == IdentityStateActive) {
        // it is a buddy on our contact list
        ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
        controller.user = aUser;
        controller.GUIDString = jidString;
        controller.managedObjectContext = [self appDelegate].context;
        
        // Pass the selected object to the new view controller.
        [controller setHidesBottomBarWhenPushed:YES];
        [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
    } else {
        // get user info from web and display as if it is searched
        NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: jidString, @"jid", @"2", @"op", nil];
        
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        
        [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"get config JSON received: %@", responseObject);
            
            [HUD hide:YES];
            NSString* type = [responseObject valueForKey:@"type"];
            if ([type isEqualToString:@"user"]) {
                ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
                controller.jsonData = responseObject;
                controller.managedObjectContext = [self appDelegate].context;
                controller.GUIDString = [ServerDataTransformer getGUIDFromServerJSON:responseObject];
                // Pass the selected object to the new view controller.
                [controller setHidesBottomBarWhenPushed:YES];
                [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
                
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"error received: %@", error);
            [HUD hide:YES];
            [ConvenienceMethods showHUDAddedTo:self animated:YES text:T(@"网络错误，无法获取用户数据") andHideAfterDelay:1];
        }];
        
    }
}



@end
