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
#import "Company.h"
#import "ModelHelper.h"
#import "AppDelegate.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif


@interface CompanyDetailViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
@property(strong,nonatomic)NSArray *sourceData;
@property(strong,nonatomic)NSArray *titleArray;
@property(strong,nonatomic)NSArray *titleEnArray;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;
@property(strong, nonatomic)UIView *faceView;
@property(strong, nonatomic)UIImageView *avatarView;
@property(strong, nonatomic)UILabel *nameLabel;
@property(strong, nonatomic)UIButton *joinButton;
@property(strong, nonatomic)UIImageView *privateView;
@property(readwrite, nonatomic)BOOL isPrivate;
@property(readwrite, nonatomic)BOOL isFollow;

@property(strong, nonatomic)UITableView * tableView;
@end

@implementation CompanyDetailViewController
@synthesize sourceData;
@synthesize sourceDict;
@synthesize tableView;
@synthesize titleArray;
@synthesize titleEnArray;
@synthesize jsonData;
@synthesize avatarView;
@synthesize nameLabel;
@synthesize joinButton;
@synthesize privateView;
@synthesize isPrivate;
@synthesize isFollow;
@synthesize managedObjectContext;
@synthesize company;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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

#define JOIN_X     130
#define JOIN_WIDTH 120
#define JOIN_HEIGHT 30
#define JOIN_Y     70

#define CELL_HEIGHT 50.0f

#define ITEM_X      15
#define ITEM_HEIGHT 16
#define ITEM_Y      (CELL_HEIGHT - ITEM_HEIGHT)/2
#define ITEM_WIDTH  80

#define DESC_X     105
#define DESC_WIDTH 180
#define DESC_HEIGHT 16
#define DESC_Y     (CELL_HEIGHT - DESC_HEIGHT)/2

#define ITEM_TAG   1
#define DESC_TAG   3

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"公司分类列表");
    self.titleArray = [[NSArray alloc]initWithObjects:T(@"邮箱"),T(@"网址"),T(@"公司成员"),T(@"描述"), nil];
    self.titleEnArray = [[NSArray alloc]initWithObjects:@"email",@"website",@"member",@"description", nil];

	// Do any additional setup after loading the view.
    self.view.backgroundColor = BGCOLOR;
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, FACE_HEIGHT, 320, self.view.bounds.size.height-FACE_HEIGHT) style:UITableViewStylePlain];
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    
    self.sourceData = [[NSArray alloc]init];
    self.sourceDict = [[NSMutableDictionary alloc]init];
    
    self.isFollow = NO;
    self.isPrivate = NO;
    
    [self.view addSubview:self.tableView];
    [self initFaceView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshFaceView];
    
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
    
    // joinButton
    self.joinButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.joinButton setFrame:CGRectMake(JOIN_X, JOIN_Y, JOIN_WIDTH, JOIN_HEIGHT)];
    [self.joinButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
    [self.joinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.joinButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.joinButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.joinButton setTitle:T(@"加入公司") forState:UIControlStateNormal];
    [self.joinButton setBackgroundImage:[UIImage imageNamed:@"green_btn.png"] forState:UIControlStateNormal];

    // private view
    self.privateView = [[UIImageView alloc] initWithFrame:CGRectMake(300, 5, 15, 15)];
    self.privateView.image = [UIImage imageNamed:@"private_icon.png"];
    
    //add sub
    [self.faceView addSubview:avatarBG];
    [self.faceView addSubview:self.avatarView];
    [self.faceView addSubview:self.privateView];
    [self.faceView addSubview:self.nameLabel];
    [self.faceView addSubview:self.joinButton];
    [self.view addSubview:self.faceView];
    
    [self.privateView setHidden:YES];
}

- (void)refreshFaceView
{

    
    
    if (self.company != nil) {
        //
        self.isPrivate  = self.company.isPrivate.boolValue;
        self.nameLabel.text = self.company.name;
        NSURL *url = [NSURL URLWithString:self.company.logo];
        [self.avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
        
        
        if (self.company.status == CompanyStateFollowed) {
            [self.joinButton setTitle:T(@"已加入") forState:UIControlStateNormal];
            [self.joinButton removeTarget:self action:@selector(joinAction) forControlEvents:UIControlEventTouchUpInside];
        }else if(self.company.status == CompanyStateUnFollowed){
            [self.joinButton setTitle:T(@"加入公司") forState:UIControlStateNormal];
            [self.joinButton addTarget:self action:@selector(joinAction) forControlEvents:UIControlEventTouchUpInside];
        }
    }else if(self.jsonData != nil){
        self.isPrivate  = [ServerDataTransformer getPrivateFromServerJSON:self.jsonData].boolValue;
        [self.joinButton addTarget:self action:@selector(joinAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.nameLabel.text = [ServerDataTransformer getCompanyNameFromServerJSON:self.jsonData];
        NSURL *url = [NSURL URLWithString:[ServerDataTransformer getLogoFromServerJSON:self.jsonData]];
        [self.avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
    }
    

    // is private
    if (self.isPrivate){
        [self.privateView setHidden:NO];
    }else{
        [self.privateView setHidden:YES];
    }
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.titleArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *enTitle = [self.titleEnArray objectAtIndex:indexPath.row];    
    
    if ([enTitle isEqualToString:@"description"]) {
        NSString *item ;
        if (self.company != nil) {
            item = self.company.desc;
        }else{
            item = [ServerDataTransformer getDescriptionFromServerJSON:self.jsonData];
        }

        UIFont *font = [UIFont systemFontOfSize:14.0f];

        CGSize size = [(item ? item : @"") sizeWithFont:font constrainedToSize:CGSizeMake(DESC_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
        if (size.height > CELL_HEIGHT) {
            return size.height + 40;
        }else{
            return CELL_HEIGHT;
        }
    }else{
        return CELL_HEIGHT;
    }
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
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.backgroundView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"cell_H50_bg.png"]];
//    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator ;
    
    
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
    
    [cell addSubview:itemLabel];
    [cell addSubview:descLabel];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == ([self.titleArray count]-1)) {
        cell.backgroundView = nil;
    }
    
    UILabel *itemLabel = (UILabel *)[cell viewWithTag:ITEM_TAG];
    itemLabel.text = [self.titleArray objectAtIndex:indexPath.row];
    
    NSString *enTitle = [self.titleEnArray objectAtIndex:indexPath.row];
    UILabel *descLabel = (UILabel *)[cell viewWithTag:DESC_TAG];
    if (self.company != nil) {
        if([enTitle isEqualToString:@"email"]){
            descLabel.text = self.company.email;
        }else if ([enTitle isEqualToString:@"website"]){
            descLabel.text = self.company.website;
        }else if ([enTitle isEqualToString:@"member"]){
            descLabel.text = T(@"点击查看");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator ;
        }else if ([enTitle isEqualToString:@"description"]){
            descLabel.text = self.company.desc;
        }
    }else{
        descLabel.text = [ServerDataTransformer getStringObjFromServerJSON:self.jsonData byName:enTitle];
        if ([enTitle isEqualToString:@"member"]){
            descLabel.text = T(@"点击查看");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator ;
        }
    }
    
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    CGSize size = [(descLabel.text ? descLabel.text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(DESC_WIDTH, 9999) lineBreakMode:UILineBreakModeWordWrap];
    NSLog(@"height %f",size.height);
    [descLabel setFrame:CGRectMake(descLabel.frame.origin.x, (cell.frame.size.height - size.height)/2+3 , DESC_WIDTH, size.height)];
    
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = BGCOLOR;
}

- (void)joinAction
{
    NSString *companyID = [ServerDataTransformer getCompanyIDFromServerJSON:self.jsonData];
    [[AppNetworkAPIClient sharedClient]followCompanyWithCompanyID:companyID withBlock:^(id responseDict, NSError *error) {
        //
        if (responseDict != nil) {
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"请求已发送") andHideAfterDelay:2];
            [self subscribeButtonPushed];
            [self refreshFaceView];
            
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"加入公司失败") andHideAfterDelay:1];
        }
    }];
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
    
//    NSString *nodeStr = [jsonData valueForKey:@"node_address"];
//    Channel *newChannel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
//    if (newChannel == nil) {
//        newChannel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:self.managedObjectContext];
//        newChannel.owner = [self appDelegate].me;
//        [[ModelHelper sharedInstance] populateIdentity:newChannel withJSONData:jsonData];
//        newChannel.state = IdentityStatePendingAddSubscription;
//    } else if (newChannel.state == IdentityStateInactive) {
//        newChannel.state = IdentityStatePendingAddSubscription;
//    } else if (newChannel.state == IdentityStatePendingRemoveSubscription) {
//        newChannel.state = IdentityStatePendingAddSubscription;
//    } else if (newChannel.state == IdentityStateActive) {
//        [ConvenienceMethods showHUDAddedTo:self.view animated:YES customView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] text:T(@"已订阅") andHideAfterDelay:2];
//        
//        [self.confirmButton setTitle:T(@"查看信息") forState:UIControlStateNormal];
//        [self.confirmButton removeTarget:self action:@selector(subscribeButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
//        [self.confirmButton addTarget:self action:@selector(sendMsgButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
//        [self.cancelButton setHidden:YES];
//        
//        return ;
//    } else if (newChannel.state == IdentityStatePendingAddSubscription){
//        
//    } else {
//        DDLogVerbose(@"CRITICAL ERROR: new channel STATE wrong (%@)", newChannel);
//        return;
//    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
