//
//  CompanyDetailViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-29.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "CompanyDetailViewController.h"
#import "AppNetworkAPIClient.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"
#import "UIImageView+AFNetworking.h"
#import "CompanyListViewController.h"
#import "CompanyMemberViewController.h"
#import "Company.h"
#import "ModelHelper.h"
#import "AppDelegate.h"
#import "Channel.h"
#import "ModelHelper.h"
#import "ChannelViewController.h"
#import "WebViewController.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif


@interface CompanyDetailViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
@property(strong,nonatomic)NSArray *sourceData;
@property(strong,nonatomic)NSArray *channelData;
@property(strong,nonatomic)NSMutableArray *titleArray;
@property(strong,nonatomic)NSMutableArray *titleEnArray;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;
@property(strong, nonatomic)UIView *faceView;
@property(strong, nonatomic)UIImageView *avatarView;
@property(strong, nonatomic)UILabel *nameLabel;
@property(strong, nonatomic)UIButton *followButton;
@property(strong, nonatomic)UIButton *csButton;
@property(strong, nonatomic)UIButton *unFollowButton;
@property(strong, nonatomic)UIImageView *privateView;
@property(readwrite, nonatomic)BOOL isPrivate;
@property(readwrite, nonatomic)BOOL isFollow;
@property(strong, nonatomic)UITableView * tableView;
@property(strong, nonatomic)UIButton *barButton;
@end

@implementation CompanyDetailViewController
@synthesize sourceData;
@synthesize channelData;
@synthesize sourceDict;
@synthesize tableView;
@synthesize titleArray;
@synthesize titleEnArray;
@synthesize jsonData;
@synthesize avatarView;
@synthesize nameLabel;
@synthesize followButton;
@synthesize csButton;
@synthesize unFollowButton;
@synthesize privateView;
@synthesize isPrivate;
@synthesize isFollow;
@synthesize managedObjectContext;
@synthesize company;
@synthesize delegate;
@synthesize barButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
    }
    return self;
}

- (void)mainMenuAction
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#define FACE_HEIGHT 125

#define AVATAR_HEIGHT 80
#define AVATAR_X    10
#define AVATAR_Y    (FACE_HEIGHT - AVATAR_HEIGHT)/2

#define NAME_X      130
#define NAME_HEIGHT 22.0f
#define NAME_Y      25
#define NAME_WIDTH  180

#define JOIN_X      130
#define JOIN_WIDTH  100
#define JOIN_HEIGHT 30
#define JOIN_Y      50
#define JOIN_WIDTH2 60

#define CS_X      130
#define CS_WIDTH  120
#define CS_HEIGHT 40
#define CS_Y      20


#define CELL_HEIGHT 50.0f

#define ITEM_X      15
#define ITEM_HEIGHT 16
#define ITEM_Y      (CELL_HEIGHT - ITEM_HEIGHT)/2
#define ITEM_WIDTH  80

#define DESC_X      105
#define DESC_WIDTH  160
#define DESC_HEIGHT 16
#define DESC_Y     (CELL_HEIGHT - DESC_HEIGHT)/2

#define LAST_WIDTH  280
#define LAST_X      (320-LAST_WIDTH)/2

#define CHANNEL_WIDTH 32
#define CHANNEL_X   DESC_X - 60
#define CHANNEL_Y (CELL_HEIGHT-CHANNEL_WIDTH)/2

#define ITEM_TAG    1
#define DESC_TAG    3
#define CHANNEL_TAG  2



- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.company != nil) {
        self.title = self.company.name;
    }else{
        self.title = [ServerDataTransformer getCompanyNameFromServerJSON:self.jsonData];
    }

    self.titleArray = [[NSMutableArray alloc]init];
    self.titleEnArray = [[NSMutableArray alloc]init];

	// Do any additional setup after loading the view.
    self.view.backgroundColor = BGCOLOR;
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, FACE_HEIGHT, 320, self.view.bounds.size.height-FACE_HEIGHT-44) style:UITableViewStylePlain];
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    
    self.sourceData = [[NSArray alloc]init];
    self.channelData = [[NSArray alloc]init];
    self.sourceDict = [[NSMutableDictionary alloc]init];
    
    self.isFollow = NO;
    self.isPrivate = NO;
    

    
    self.titleArray = [[NSMutableArray alloc]initWithObjects:T(@"邮箱"),T(@"网址"),T(@"公司成员"),T(@"频道"), nil];
    self.titleEnArray = [[NSMutableArray alloc]initWithObjects: @"email",@"website",@"member",@"channel", nil];
    
    [self.view addSubview:self.tableView];
    [self initFaceView];
    [self initHeaderView];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshFaceView];
    [self populateChannelData];
}


- (void)initFaceView
{
    self.faceView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, FACE_HEIGHT)];
    [self.faceView setBackgroundColor:RGBCOLOR(83, 71, 65)];
    
    // avarat bg
    UIImageView *avatarBG = [[UIImageView alloc]initWithFrame:CGRectMake(AVATAR_X, AVATAR_Y-AVATAR_X, AVATAR_HEIGHT+AVATAR_X*2, AVATAR_HEIGHT+AVATAR_X*2)];
    [avatarBG setBackgroundColor:RGBACOLOR(255, 255, 255, 0.1)];
    [avatarBG.layer setMasksToBounds:YES];
    [avatarBG.layer setCornerRadius:(AVATAR_HEIGHT+AVATAR_X*2)/2];
    
    // avatarview
    self.avatarView = [[UIImageView alloc]initWithFrame:CGRectMake(AVATAR_X*2, AVATAR_Y, AVATAR_HEIGHT, AVATAR_HEIGHT)];
    [avatarView.layer setMasksToBounds:YES];
    [avatarView.layer setCornerRadius:AVATAR_HEIGHT/2];
    
    // namelagel
    self.nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(NAME_X, NAME_Y, NAME_WIDTH, NAME_HEIGHT)];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.font = [UIFont boldSystemFontOfSize:NAME_HEIGHT];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.textColor = [UIColor whiteColor];
    
    // followButton
    self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.followButton setFrame:CGRectMake(JOIN_X, JOIN_Y, JOIN_WIDTH, JOIN_HEIGHT)];
    [self.followButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
    [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.followButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.followButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.followButton setTitle:T(@"加入公司") forState:UIControlStateNormal];
    [self.followButton setBackgroundImage:[UIImage imageNamed:@"green_btn.png"] forState:UIControlStateNormal];

    // unFollowButton
    self.unFollowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.unFollowButton setFrame:CGRectMake(JOIN_X+JOIN_WIDTH+10, JOIN_Y, JOIN_WIDTH2, JOIN_HEIGHT)];
    [self.unFollowButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
    [self.unFollowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.unFollowButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.unFollowButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.unFollowButton setTitle:T(@"退出") forState:UIControlStateNormal];
    [self.unFollowButton setBackgroundImage:[UIImage imageNamed:@"green_btn_120.png"] forState:UIControlStateNormal];

    // csButton
    self.csButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.csButton setFrame:CGRectMake(CS_X, CS_Y, CS_WIDTH, CS_HEIGHT)];
    [self.csButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
    [self.csButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.csButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.csButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.csButton setTitle:T(@"联系客服") forState:UIControlStateNormal];
    [self.csButton setBackgroundImage:[UIImage imageNamed:@"green_cs_btn.png"] forState:UIControlStateNormal];
    [self.csButton setTitleEdgeInsets:UIEdgeInsetsMake(8, 20, 8, 8)];
    
    // private view
    self.privateView = [[UIImageView alloc] initWithFrame:CGRectMake(300, 5, 15, 15)];
    self.privateView.image = [UIImage imageNamed:@"private_icon.png"];
    
    //add sub
    [self.faceView addSubview:avatarBG];
    [self.faceView addSubview:self.avatarView];
    [self.faceView addSubview:self.privateView];
//    [self.faceView addSubview:self.nameLabel]; // title = name
    [self.faceView addSubview:self.followButton];
    [self.faceView addSubview:self.unFollowButton];
    [self.faceView addSubview:self.csButton];
    [self.view addSubview:self.faceView];
    
    [self.privateView setHidden:YES];
    [self.unFollowButton setHidden:YES];
    
}

- (void)refreshFaceView
{    
    if (self.company != nil) {
        //
        self.isPrivate  = self.company.isPrivate.boolValue;
//        self.nameLabel.text = self.company.name;
        NSURL *url = [NSURL URLWithString:self.company.logo];
        [self.avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
        
        if (self.company.status == CompanyStateFollowed) {

            
            [self.followButton setTitle:T(@"已加入") forState:UIControlStateNormal];
            [self.followButton setBackgroundImage:[UIImage imageNamed:@"brown_btn.png"] forState:UIControlStateNormal];
            [self.followButton removeTarget:self action:@selector(followAction) forControlEvents:UIControlEventTouchUpInside];
            [self.csButton addTarget:self action:@selector(customServiceAction) forControlEvents:UIControlEventTouchUpInside];
            [self.unFollowButton addTarget:self action:@selector(unFollowAction) forControlEvents:UIControlEventTouchUpInside];

            [self.unFollowButton setHidden:NO];
            [self.csButton setHidden:NO];
            
            [self.followButton setFrame:CGRectMake(JOIN_X, JOIN_Y+30, JOIN_WIDTH, JOIN_HEIGHT)];
            [self.unFollowButton setFrame:CGRectMake(JOIN_X+JOIN_WIDTH+10, JOIN_Y+30, JOIN_WIDTH2, JOIN_HEIGHT)];

        }else if(self.company.status == CompanyStateUnFollowed){
            
            [self.followButton setTitle:T(@"加入公司") forState:UIControlStateNormal];
            [self.followButton addTarget:self action:@selector(followAction) forControlEvents:UIControlEventTouchUpInside];
            [self.followButton setBackgroundImage:[UIImage imageNamed:@"green_btn.png"] forState:UIControlStateNormal];
            [self.unFollowButton setHidden:YES];
            [self.csButton setHidden:YES];
            [self.followButton setFrame:CGRectMake(JOIN_X, JOIN_Y, JOIN_WIDTH, JOIN_HEIGHT)];
            [self.unFollowButton setFrame:CGRectMake(JOIN_X+JOIN_WIDTH+10, JOIN_Y, JOIN_WIDTH2, JOIN_HEIGHT)];
        }
    }else if(self.jsonData != nil){
        self.isPrivate  = [ServerDataTransformer getPrivateFromServerJSON:self.jsonData].boolValue;
        [self.followButton addTarget:self action:@selector(followAction) forControlEvents:UIControlEventTouchUpInside];
        
//        self.nameLabel.text = [ServerDataTransformer getCompanyNameFromServerJSON:self.jsonData];
        NSURL *url = [NSURL URLWithString:[ServerDataTransformer getLogoFromServerJSON:self.jsonData]];
        [self.avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
        [self.unFollowButton setHidden:YES];
        [self.csButton setHidden:YES];
        [self.followButton setFrame:CGRectMake(JOIN_X, JOIN_Y, JOIN_WIDTH, JOIN_HEIGHT)];
        [self.unFollowButton setFrame:CGRectMake(JOIN_X+JOIN_WIDTH+10, JOIN_Y, JOIN_WIDTH2, JOIN_HEIGHT)];
    }
    
    
    // is private
    if (self.isPrivate){
        [self.privateView setHidden:NO];
    }else{
        [self.privateView setHidden:YES];
    }
    
    [self.tableView reloadData];
}

- (void)initHeaderView
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 100)];
    headerView.backgroundColor = BGCOLOR;
    
    UIView *separateLine = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 1)];
    separateLine.backgroundColor = SEPCOLOR;
    
    NSString *descString;
    if (self.company != nil) {
        descString = self.company.desc;
    }else{
        descString = [ServerDataTransformer getDescriptionFromServerJSON:self.jsonData];
    }
    
    UILabel *descLabel = [[UILabel alloc]initWithFrame:CGRectMake(LAST_X, 0, LAST_WIDTH, 10)];
    descLabel.backgroundColor = [UIColor clearColor];
    descLabel.font = [UIFont systemFontOfSize:14.0f];
    descLabel.textAlignment = NSTextAlignmentLeft;
    descLabel.numberOfLines = 0;
    descLabel.textColor = LIVID_COLOR;
    descLabel.text = descString;
    
    CGSize size = [(descString ? descString : @"") sizeWithFont:descLabel.font constrainedToSize:CGSizeMake(LAST_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    [headerView setFrame:CGRectMake(0, 0, 320, size.height+JOIN_HEIGHT)];
    [descLabel setFrame:CGRectMake(LAST_X, JOIN_HEIGHT/2 , LAST_WIDTH, size.height)];
    [separateLine setFrame:CGRectMake(0, size.height+JOIN_HEIGHT-1, 320, 1)];
    
    [headerView addSubview:separateLine];
    [headerView addSubview:descLabel];
    self.tableView.tableHeaderView = headerView;

}

// 频道channel 数据
- (void)populateChannelData
{
    NSString  *companyID;
    NSMutableArray *tmpArray = [[NSMutableArray alloc]init];
    self.channelData = [[NSArray alloc]init];
    
    if (self.company != nil) {
        companyID = self.company.companyID;
    }else{
        companyID = [ServerDataTransformer getCompanyIDFromServerJSON:self.jsonData];
    }
    [[AppNetworkAPIClient sharedClient]getCompanyChannelWithCompanyID:companyID withBlock:^(id responseObject, NSError *error) {
        //
        if (responseObject != nil) {
            self.sourceDict = responseObject;
            self.sourceData = [self.sourceDict allValues];
            
            NSUInteger i;
            for(i = 0; i < [self.sourceData count]; i++)
            {
                NSDictionary *dict = [self.sourceData objectAtIndex:i];                
                [tmpArray addObject:dict];
            }
            
            self.channelData = [[NSArray alloc]initWithArray:tmpArray];
            if ([self.channelData count] > 0) {
                [self.tableView reloadData];
            }
        }
    }];

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
    NSUInteger count = [self.titleArray count] + [self.channelData count];
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

        return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CompanyDetailCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;


    UILabel *itemLabel = [[UILabel alloc]initWithFrame:CGRectMake(ITEM_X, ITEM_Y, ITEM_WIDTH, ITEM_HEIGHT)];
    itemLabel.backgroundColor = [UIColor clearColor];
    itemLabel.font = [UIFont systemFontOfSize:16.0f];
    itemLabel.textAlignment = NSTextAlignmentLeft;
    itemLabel.textColor = RGBCOLOR(107, 107, 107);
    itemLabel.tag = ITEM_TAG;
    

    UILabel *descLabel = [[UILabel alloc]initWithFrame:CGRectMake(DESC_X, DESC_Y, DESC_WIDTH, DESC_HEIGHT)];
    descLabel.backgroundColor = [UIColor clearColor];
    descLabel.font = [UIFont systemFontOfSize:14.0f];
    descLabel.textAlignment = NSTextAlignmentLeft;
    descLabel.numberOfLines = 0;
    descLabel.textColor = LIVID_COLOR;
    descLabel.tag = DESC_TAG;
    
    // Create an image view for the quarter image.
	CGRect imageRect = CGRectMake(CHANNEL_X, CHANNEL_Y, CHANNEL_WIDTH, CHANNEL_WIDTH);
    
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:imageRect];
    avatarImage.tag = CHANNEL_TAG;
    CALayer *avatarLayer = [avatarImage layer];
    [avatarLayer setMasksToBounds:YES];
    [avatarLayer setCornerRadius:5.0];
    [cell.contentView addSubview:avatarImage];
    
    [cell addSubview:avatarImage];
    [cell addSubview:itemLabel];
    [cell addSubview:descLabel];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger descCount = [self.titleArray count];
    
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:ITEM_TAG];
    UILabel *descLabel = (UILabel *)[cell viewWithTag:DESC_TAG];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:CHANNEL_TAG];
    if (indexPath.row < descCount) {
        itemLabel.text = [self.titleArray objectAtIndex:indexPath.row];
        NSString *enTitle = [self.titleEnArray objectAtIndex:indexPath.row];
        if (self.company != nil && self.company.status == CompanyStateFollowed) {
            if([enTitle isEqualToString:@"email"]){
                descLabel.text = self.company.email;
            }else if ([enTitle isEqualToString:@"website"]){
                descLabel.text = self.company.website;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }else if ([enTitle isEqualToString:@"member"]){
                descLabel.text = T(@"点击查看");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }else{
            descLabel.text = [ServerDataTransformer getStringObjFromServerJSON:self.jsonData byName:enTitle];
            if ([enTitle isEqualToString:@"member"]){
                descLabel.text = T(@"请先加入公司");
            }else if ([enTitle isEqualToString:@"website"]){
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        UIFont *font = [UIFont systemFontOfSize:14.0f];
        
        CGSize size = [(descLabel.text ? descLabel.text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(DESC_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
        
        CGFloat posY =  (cell.frame.size.height - size.height)/2+3;
        [descLabel setFrame:CGRectMake(DESC_X, posY , DESC_WIDTH, size.height)];
        
        [itemLabel setHidden:NO];
        [descLabel setHidden:NO];
        [imageView setHidden:YES];

    }else{
        if ([self.channelData count] > 0) {
            NSDictionary *dataDict = [self.channelData objectAtIndex:(indexPath.row - descCount)];
            
            descLabel.text = [ServerDataTransformer getNicknameFromServerJSON:dataDict];
            //set avatar
            NSURL *url = [NSURL URLWithString:[ServerDataTransformer getThumbnailFromServerJSON:dataDict]];
            [imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"placeholder_user.png"]];
            [descLabel setFrame:CGRectMake(DESC_X, descLabel.frame.origin.y, descLabel.frame.size.width, descLabel.frame.size.height)];
            
            if (self.company.status == CompanyStateFollowed) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }else{
                
            }
            
            
            [itemLabel setHidden:YES];
            [descLabel setHidden:NO];
            [imageView setHidden:NO];
        }
        
    }

}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = BGCOLOR;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger descCount = [self.titleArray count];

    if (indexPath.row < descCount) {
        NSString *enTitle = [self.titleEnArray objectAtIndex:indexPath.row];
        if ([enTitle isEqualToString:@"member"]) {
            NSString *companyID;
            
            if (self.company != nil && self.company.status == CompanyStateFollowed) {
                companyID = self.company.companyID;
                CompanyMemberViewController *controller = [[CompanyMemberViewController alloc]initWithNibName:nil bundle:nil];
                controller.companyID = companyID;
                [self.navigationController pushViewController:controller animated:YES];
            }
            
        }else if ([enTitle isEqualToString:@"website"]){
            WebViewController *controller = [[WebViewController alloc]initWithNibName:nil bundle:nil];
            if (self.company != nil) {
                controller.title = self.company.name;
                controller.urlString = self.company.website;
            }else{
                controller.title = [ServerDataTransformer getCompanyNameFromServerJSON:self.jsonData];
                controller.urlString = [ServerDataTransformer getWebsiteFromServerJSON:self.jsonData];
            }
            
            [self.navigationController pushViewController:controller animated:YES];
        }else if ([enTitle isEqualToString:@"email"]){
            NSString *emailStr;
            if (self.company != nil) {
                emailStr = [NSString stringWithFormat:
                                 @"mailto:%@",self.company.email ];
            }else{
                emailStr = [NSString stringWithFormat:
                                 @"mailto:%@",[ServerDataTransformer getEmailFromServerJSON:self.jsonData]];
            }
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailStr]];
        }
    }else{
        if ([self.channelData count] > 0) {

            NSDictionary *dataDict = [self.channelData objectAtIndex:(indexPath.row - descCount)];
            if (self.company.status == CompanyStateFollowed) {
                [self getDict:dataDict];
            }
        }
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getDict:(NSDictionary *)dict
{
    Channel *aChannel = [[ModelHelper sharedInstance]findChannelWithNode:[dict objectForKey:@"node_address"]];
    
    if (aChannel != nil && aChannel.state == IdentityStateActive) {
        ChannelViewController *controller = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
        controller.delegate = [self appDelegate].contactListController;
        controller.managedObjectContext = [self appDelegate].context;
        controller.channel = aChannel;
        // Pass the selected object to the new view controller.
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        // get user info from web and display as if it is searched

        ChannelViewController *controller = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
        controller.jsonData = dict;
        controller.delegate = [self appDelegate].contactListController;
        controller.managedObjectContext = [self appDelegate].context;
        
        // Pass the selected object to the new view controller.
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
        
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)followAction
{
    NSString *companyID = [ServerDataTransformer getCompanyIDFromServerJSON:self.jsonData];
    [[AppNetworkAPIClient sharedClient]followCompanyWithCompanyID:companyID withBlock:^(id responseDict, NSError *error) {
        //
        if (responseDict != nil) {
            if (self.isPrivate) {
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"请等待批准") andHideAfterDelay:2];
            }else{
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"已加入") andHideAfterDelay:2];
            }
            [self subscribeButtonPushed];
            [self refreshFaceView];
            [self populateChannelData];
            
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"加入公司失败") andHideAfterDelay:1];
        }
    }];
}

- (void)unFollowAction
{
    NSString *companyID = self.company.companyID;
    [[AppNetworkAPIClient sharedClient]unfollowCompanyWithCompanyID:companyID withBlock:^(id responseDict, NSError *error) {
        //
        if (responseDict != nil) {
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"请求已发送") andHideAfterDelay:2];
            [self unSubscribeButtonPushed];
            //返回上一层
            [self.navigationController popViewControllerAnimated:YES];
            
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"推出公司失败") andHideAfterDelay:1];
        }
    }];
}

// 联系客服
- (void)customServiceAction
{
    if (self.company != nil) {
        
        NSString *nodeStr = [NSString stringWithFormat:@"channel#0#%@",self.company.companyID];
        self.delegate  = [self appDelegate].contactListController;
        
        Channel *csChannel = [[ModelHelper sharedInstance] findChannelWithGUID:@"0" withCompanyID:self.company.companyID ];
        
        if (csChannel != nil) {
            csChannel.node = nodeStr;
            csChannel.displayName = [NSString stringWithFormat:@"%@ 客服",self.company.name];
            csChannel.ePostalID = self.company.serverbotJID;
            csChannel.guid = @"0";
            csChannel.companyID = self.company.companyID;
            csChannel.csContactPostalID = self.company.serverbotJID;
            
            [self.managedObjectContext save:nil];
            
            [self.delegate viewController:self didChatIdentity:csChannel];
            
        }else{
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Channel" inManagedObjectContext:self.managedObjectContext];
            
            Channel *aChannel = [[Channel alloc]initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
            aChannel.node = nodeStr;
            aChannel.displayName = [NSString stringWithFormat:@"%@ 客服",self.company.name];
            aChannel.ePostalID = self.company.serverbotJID;
            aChannel.guid = @"0";
            aChannel.companyID = self.company.companyID;
            aChannel.csContactPostalID = self.company.serverbotJID;
                        
            [self.managedObjectContext save:nil];

            [self.delegate viewController:self didChatIdentity:aChannel];

        }

        
        
        
    }
}

-(void)subscribeButtonPushed
{
    Company *newCompany = [[ModelHelper sharedInstance] findCompanyWithCompanyID:
                            [ServerDataTransformer getCompanyIDFromServerJSON:self.jsonData]];
    if (newCompany == nil) {
        newCompany = [NSEntityDescription insertNewObjectForEntityForName:@"Company" inManagedObjectContext:self.managedObjectContext];
        newCompany.owner = [self appDelegate].me;
        [[ModelHelper sharedInstance] populateCompany:newCompany withServerJSONData:self.jsonData];
        
        if (self.isPrivate) {
            newCompany.status  = CompanyStateUnFollowed;
        }else{
            newCompany.status  = CompanyStateFollowed;
        }
        self.company = newCompany;
    }
}

- (void)unSubscribeButtonPushed
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Company" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(companyID = %@)", self.company.companyID];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *companyArray = [moc executeFetchRequest:request error:&error];
    
    if ([companyArray count] > 0){
        Company *aCompany = [companyArray objectAtIndex:0];
        [self.managedObjectContext deleteObject:aCompany];
        [self.managedObjectContext save:nil];
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
