//
//  WSBubbleTableView.m
//  iMedia
//
//  Created by mac on 12-11-12.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WSBubbleTableView.h"
#import "WSBubbleData.h"



@implementation WSBubbleTableView

@synthesize snapInterval;
@synthesize showAvatars;
@synthesize bubbleSection;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
//    self.bubbleSection = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.bubbleSection count]; i++) {
        WSBubbleData *tmp = [self.bubbleSection  objectAtIndex:i];
        NSLog(@"%@",tmp.content);
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableView section delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= [self.bubbleSection count]) return 1;
    
    return [[self.bubbleSection objectAtIndex:section] count] + 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int result = [self.bubbleSection count];
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableView section delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier andIndexPath:indexPath];
    }
    
    
    // Configure the cell...
//    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}


- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier andIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
    cell.backgroundView = cellBgView;
    
    UIImageView *cellBgSelectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg_highlighted.png"]];
    cell.selectedBackgroundView =  cellBgSelectedView;
    
    
    WSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    
    cell.textLabel.text = data.content;
    NSLog(@"%@",data.content);
    
    return  cell;
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
