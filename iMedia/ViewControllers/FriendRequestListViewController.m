//
//  FriendRequestListViewController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/29/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FriendRequestListViewController.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"
#import "RequestViewController.h"
#import "UIImageView+AFNetworking.h"
#import "NSDate+timesince.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
#define ROW_HEIGHT  130.0

@interface FriendRequestListViewController ()

@end

@implementation FriendRequestListViewController

@synthesize friendRequestJSONArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = T(@"Request List");
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = BGCOLOR;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.friendRequestJSONArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Requestlist";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    
    // Configure the cell...
    [self configureCell:cell forIndexPath:indexPath];    
    
    return cell;
}
////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuring table view cells
////////////////////////////////////////////////////////////////////////////////////
#define NAME_TAG 1
#define TIME_TAG 2
#define SNS_TAG 20
#define AVATAR_TAG 3
#define SUMMARY_TAG 4

#define LEFT_COLUMN_OFFSET 30.0
#define LEFT_COLUMN_WIDTH 36.0
#define TOP_OFFEST 40.0

#define MIDDLE_COLUMN_OFFSET 100.0
#define MIDDLE_COLUMN_WIDTH 150.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 12.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SNS_SIDE 15.0
#define SUMMARY_WIDTH_OFFEST 30.0
#define SUMMARY_WIDTH 80.0

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];    
    
    UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"request_list_bg.png"]];
    [cellBgView setFrame:CGRectMake(10, 10, 300, 130)];
    [cell.contentView addSubview:cellBgView];

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.backgroundColor = [UIColor clearColor];
    
    UILabel *label;
    CGRect rect;
    // Create an image view for the quarter image.
	CGRect imageRect = CGRectMake(LEFT_COLUMN_OFFSET, TOP_OFFEST , IMAGE_SIDE, IMAGE_SIDE);
	CGRect snsRect;
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = AVATAR_TAG;
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [avatarLayer setBorderWidth:1.0];
    [avatarLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    [cell.contentView addSubview:avatarImage];
    
    
    // Create a label for the time.
	rect = CGRectMake(LEFT_COLUMN_OFFSET, LABEL_HEIGHT -5,  MIDDLE_COLUMN_WIDTH , LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TIME_TAG;
    label.numberOfLines = 1;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(153, 153, 153);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];

    
    // Create a label for the user name.
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, TOP_OFFEST , MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NAME_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(107, 107, 107);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];
    
    // Create a label for the add btn.
	rect = CGRectMake(240, 113,  60 , LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
    label.numberOfLines = 1;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(198, 198, 198);
    label.backgroundColor = [UIColor clearColor];
    label.text = T(@"添加");
    [cell.contentView addSubview:label];
    
    // set avatar
    NSMutableArray *snsArray = [[NSMutableArray alloc] initWithObjects:@"weibo",@"douban", nil];
    UIImageView *snsImage;
    
    for(int i=0;i<[snsArray count];i++)  
    {  
        snsRect = CGRectMake(MIDDLE_COLUMN_OFFSET + MIDDLE_COLUMN_WIDTH + (SNS_SIDE + 3)* i, TOP_OFFEST+3 , SNS_SIDE, SNS_SIDE);
        snsImage = [[UIImageView alloc] initWithFrame:snsRect];
        snsImage.tag = SNS_TAG + i;
        
        [cell.contentView addSubview:snsImage];
    } 
    
    
    // Create a label for the summary
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, TOP_OFFEST + LABEL_HEIGHT, SUMMARY_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = SUMMARY_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentCenter;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.backgroundColor = RGBCOLOR(236, 238, 240);
    
    [label.layer setMasksToBounds:YES];
    [label.layer setCornerRadius:3.0];
	[cell.contentView addSubview:label];    
    
    return  cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    id obj = [self.friendRequestJSONArray objectAtIndex:indexPath.row];
    
    // set max size
    CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*1);
    CGSize summaryMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*2);
    
    
    // set the avatar
    UIImageView *imageView;
    CGFloat _labelHeight;
    
    //set avatar
    imageView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
    NSString *imageUrl = [ServerDataTransformer getAvatarFromServerJSON:obj];
    [imageView setImageWithURL:[NSURL URLWithString:imageUrl]];
    
    //set sns icon
    NSMutableArray *snsArray = [[NSMutableArray alloc] initWithObjects:@"weibo",@"douban", nil];    
    for (int i =0; i< [snsArray count]; i++) {
        imageView = (UIImageView *)[cell viewWithTag:SNS_TAG + i];
        
        if ([[snsArray objectAtIndex:i] isEqual:@"weibo"]) {
            imageView.image = [UIImage imageNamed:@"sns_icon_weibo.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"douban"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_douban.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"wechat"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_wechat.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"kaixin"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_kaixin.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"renren"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_renren.png"];
        }else if([[snsArray objectAtIndex:i] isEqual:@"tmweibo"]){
            imageView.image = [UIImage imageNamed:@"sns_icon_tmweibo.png"];
        }
    }
    
    // set the time text
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:TIME_TAG];
    timeLabel.text =  [[obj valueForKey:@"add_friend_request_date"] timesince];
    
    // set the name text
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    NSString *_nameString = [ServerDataTransformer getNicknameFromServerJSON:obj];

    CGSize labelSize = [_nameString sizeWithFont:nameLabel.font constrainedToSize:nameMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (labelSize.height > LABEL_HEIGHT) {
        _labelHeight = 10.0;
    }else {
        _labelHeight = 20.0;
    }
    nameLabel.text = _nameString;
    nameLabel.frame = CGRectMake(nameLabel.frame.origin.x, TOP_OFFEST, labelSize.width, labelSize.height);
    
    // set the user signature
    UILabel *signatureLabel = (UILabel *)[cell viewWithTag:SUMMARY_TAG];
    NSString *signature =[ServerDataTransformer getSignatureFromServerJSON:obj];
    
    CGSize signatureSize = [signature sizeWithFont:signatureLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
    if (signatureSize.height > LABEL_HEIGHT) {
        _labelHeight = TOP_OFFEST+LABEL_HEIGHT+2;
    }else {
        _labelHeight = TOP_OFFEST+LABEL_HEIGHT+10;
    }
    signatureLabel.text = signature;
    signatureLabel.frame = CGRectMake(signatureLabel.frame.origin.x, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 170.0;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    RequestViewController *requestViewController = [[RequestViewController alloc]initWithNibName:nil bundle:nil];    
    requestViewController.jsonData = [self.friendRequestJSONArray objectAtIndex:indexPath.row];
    NSLog(@"%@",[self.friendRequestJSONArray objectAtIndex:indexPath.row]);
    [self.navigationController pushViewController:requestViewController animated:YES];

}

@end
