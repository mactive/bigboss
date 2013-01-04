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
#import "UIImageView+AFNetworking.h"
#import "NSDate+timesince.h"
#import "FriendRequest.h"
#import "NSObject+SBJson.h"
#import "ContactDetailController.h"
#import "AppDelegate.h"
#import "ModelHelper.h"
#import "DDLog.h"
#import "MBProgressHUD.h"
#import "AppNetworkAPIClient.h"
#import "ConvenienceMethods.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
#define ROW_HEIGHT  130.0

@interface FriendRequestListViewController ()

@end

@implementation FriendRequestListViewController

@synthesize friendRequestArray;

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
    
    self.title = T(@"好友请求列表");
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = BGCOLOR;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
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
    return [self.friendRequestArray count];
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
#define AVATAR_TAG 3
#define SUMMARY_TAG 4
#define STATE_TAG 5

#define LEFT_COLUMN_OFFSET 30.0
#define LEFT_COLUMN_WIDTH 36.0
#define TOP_OFFEST 40.0

#define MIDDLE_COLUMN_OFFSET 100.0
#define MIDDLE_COLUMN_WIDTH 180.0

#define RIGHT_COLUMN_OFFSET 230.0
#define RIGHT_COLUMN_WIDTH  60

#define MAIN_FONT_SIZE 16.0
#define SUMMARY_FONT_SIZE 12.0
#define LABEL_HEIGHT 20.0
#define SUMMARY_PADDING 10.0

#define IMAGE_SIDE 50.0
#define SUMMARY_WIDTH_OFFEST 30.0
#define SUMMARY_WIDTH 150.0

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
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = AVATAR_TAG;
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
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
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, TOP_OFFEST-5 , MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NAME_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(107, 107, 107);
    label.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:label];
    
    // Create a label for the add btn.
	rect = CGRectMake(230, 113,  60 , LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
    label.tag = STATE_TAG;
    label.numberOfLines = 1;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(220, 220, 220);
    label.backgroundColor = [UIColor clearColor];
    label.text = T(@"添加");
    [cell.contentView addSubview:label];
    
    // Create a label for the summary
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, TOP_OFFEST + LABEL_HEIGHT-5, SUMMARY_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = SUMMARY_TAG;
    label.numberOfLines = 2;
	label.font = [UIFont systemFontOfSize:SUMMARY_FONT_SIZE];
	label.textAlignment = UITextAlignmentLeft;
    label.textColor = RGBCOLOR(158, 158, 158);
    label.backgroundColor = [UIColor clearColor];

	[cell.contentView addSubview:label];    
    
    return  cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    FriendRequest *request = [self.friendRequestArray objectAtIndex:indexPath.row];
    NSDictionary *localDict = [request.userJSONData JSONValue];
    
    // set max size
    CGSize nameMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*1);
    CGSize summaryMaxSize = CGSizeMake(MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT*2);
    
    
    // set the avatar
    UIImageView *imageView;
    CGFloat _labelHeight;
    
    //set avatar
    imageView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
    NSString *imageUrl = [ServerDataTransformer getAvatarFromServerJSON:localDict];
    [imageView setImageWithURL:[NSURL URLWithString:imageUrl]];
    

    // set the time text
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:TIME_TAG];
    timeLabel.text =  [request.requestDate timesince];
    
    // set the name text
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    NSString *_nameString = [ServerDataTransformer getNicknameFromServerJSON:localDict];
    
    // set the state text
    UILabel *stateLabel = (UILabel *)[cell viewWithTag:STATE_TAG];
    if (request.state == FriendRequestDeclined) {
        stateLabel.text = T(@"已拒绝");
        stateLabel.textColor = RGBCOLOR(177, 177, 177);

    } else if (request.state == FriendRequestApproved) {
        stateLabel.text = T(@"已添加");
        stateLabel.textColor = RGBCOLOR(177, 177, 177);

    } else {
        stateLabel.text = T(@"+ 添加");
        stateLabel.textColor = RGBCOLOR(220, 220, 220);
    }


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
    NSString *signature =[ServerDataTransformer getSignatureFromServerJSON:localDict];
    
    if ([signature length] > 0) {
        CGSize signatureSize = [signature sizeWithFont:signatureLabel.font constrainedToSize:summaryMaxSize lineBreakMode: UILineBreakModeTailTruncation];
        if (signatureSize.height > LABEL_HEIGHT) {
            _labelHeight = TOP_OFFEST+LABEL_HEIGHT+2;
        }else {
            _labelHeight = TOP_OFFEST+LABEL_HEIGHT+10;
        }
        signatureLabel.text = signature;
        signatureLabel.frame = CGRectMake(signatureLabel.frame.origin.x, _labelHeight, signatureSize.width + SUMMARY_PADDING, signatureSize.height+SUMMARY_PADDING);
    }else{
        [signatureLabel removeFromSuperview];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 170.0;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FriendRequest *request = [self.friendRequestArray objectAtIndex:indexPath.row];
    [self getDict:request];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getDict:(FriendRequest *)request
{
    
    NSString * guidString = request.guid;
    // if the user already exist - then show the user
    User* aUser = [[ModelHelper sharedInstance] findUserWithGUID:guidString];
    
    if (aUser != nil && aUser.state == IdentityStateActive) {
        // it is a buddy on our contact list
        ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
        controller.user = aUser;
        controller.GUIDString = guidString;
        controller.managedObjectContext = [self appDelegate].context;
        
        // Pass the selected object to the new view controller.
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        // get user info from web and display as if it is searched
        NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: guidString, @"guid", @"1", @"op", nil];
        
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        
        [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            DDLogVerbose(@"get user received: %@", responseObject);
            
            [HUD hide:YES];
            NSString* type = [responseObject valueForKey:@"type"];
            if ([type isEqualToString:@"user"]) {
                ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
                controller.jsonData = responseObject;
                controller.managedObjectContext = [self appDelegate].context;
                controller.GUIDString = guidString;
                controller.request = request;
                // Pass the selected object to the new view controller.
                [controller setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //
            DDLogVerbose(@"error received: %@", error);
            [HUD hide:YES];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误，无法获取用户数据") andHideAfterDelay:1];
        }];
        
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = 0;
    NSInteger numberOfSections = [self.tableView numberOfSections];
    if (numberOfSections > 0) {
        numberOfRows = [self.tableView numberOfRowsInSection:numberOfSections-1];
    }
    if (numberOfRows) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:numberOfSections-1] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


@end
