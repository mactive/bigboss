//
//  WSBubbleTableView.m
//  iMedia
//
//  Created by mac on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTableView.h"
#import "WSBubbleData.h"
#import "WSBubbleSectionHeader.h"
#import "WSBubbleTableViewCell.h"
#import "RateViewController.h"
#import "WebViewController.h"
#import "AppDelegate.h"
#import "XMPPFramework.h"
#import "ConversationsController.h"
#import "Conversation.h"



@implementation WSBubbleTableView

@synthesize snapInterval;
@synthesize showAvatars;
@synthesize bubbleSection;

#define SECTION_HEIGHT 28

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.dataSource = self;
        self.delegate = self;
        self.snapInterval = 120;
    }
    return self;
}

- (void)reloadData
{
    [super reloadData];

    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    
    // Cleaning up
//	self.bubbleSection = nil;
//  self.bubbleSection = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.bubbleSection count]; i++) {
        NSMutableArray *myarray = [self.bubbleSection  objectAtIndex:i];

        for (int j = 0; j < [myarray count]; j++) {
            WSBubbleData *tmp = [myarray objectAtIndex:j];
            NSLog(@"%i - %i   %@", i,j, tmp.content);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableView section delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= [self.bubbleSection count]) return 1;
    
    return [[self.bubbleSection objectAtIndex:section ] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int result = [self.bubbleSection count];
    if (result > 0 ) {
        return result;
    }else{
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    WSBubbleSectionHeader *sectionView = [[WSBubbleSectionHeader alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, SECTION_HEIGHT)];
    WSBubbleData *firstRowData = [[self.bubbleSection objectAtIndex:section] objectAtIndex:0];
    
    sectionView.date = firstRowData.date;
    return sectionView;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableView cell delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WSBubbleData *rowData = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    CGFloat cellHeight = MAX(rowData.insets.top + rowData.cellHeight + rowData.insets.bottom, self.showAvatars ? 55 : 0);
    return  cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    WSBubbleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    WSBubbleData *rowData = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (cell == nil) {
        cell = [[WSBubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.data = rowData;    
    return cell;
}


- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier andIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    cell.backgroundColor = [UIColor clearColor];
    
    WSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = data.content;
    return  cell;
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - cell did selected
//////////////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Standard bubble
    WSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (data.type == BubbleTypeMine || data.type == BubbleTypeSomeoneElse) {
#warning TODO 点击去到那个人的profile页面
    }
    
    if (data.type == BubbleTypeRateview) {
        RateViewController *rateViewController = [[RateViewController alloc]initWithNibName:nil bundle:nil];
        rateViewController.conversionKey = data.content;

        [[self appDelegate].conversationController.chatDetailController.navigationController presentModalViewController:rateViewController animated:YES];
        
        [[self appDelegate].conversationController.chatDetailController.conversation removeMessagesObject:data.msg];
        data.msg = nil;
        [[self appDelegate].conversationController contentChanged];
    }
    if (data.type == BubbleTypeTemplateview) {
        
        NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:data.content error:nil];
        NSString* imageString = [[element elementForName:@"link9"] stringValue];
        
        WebViewController *controller = [[WebViewController alloc]initWithNibName:nil bundle:nil];
        controller.urlString = imageString;
        
        [[self appDelegate].conversationController.chatDetailController.navigationController setHidesBottomBarWhenPushed:YES];
        [[self appDelegate].conversationController.chatDetailController.navigationController pushViewController:controller animated:YES];
    }
}



////////////////////////////////////////////////////////////////////////
//  Change Default Scrolling Behavior of UITableView Section Header
//  如何让 UITableView 的 headerView跟随 cell一起滚动
////////////////////////////////////////////////////////////////////////

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = SECTION_HEIGHT;
    UIEdgeInsets insets = scrollView.contentInset;
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, insets.bottom, 0);
    } else if (scrollView.contentOffset.y >= sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, insets.bottom, 0);
    }
}



- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
