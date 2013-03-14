//
//  CompanyMemberViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-30.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "CompanyMemberViewController.h"
#import "AppNetworkAPIClient.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"
#import "UIImageView+AFNetworking.h"
#import "CompanyDetailViewController.h"
#import "ContactDetailController.h"
#import "Company.h"
#import "ModelHelper.h"
#import "AppDelegate.h"
#import "Me.h"
#import "CompanyMemberTableViewCell.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface CompanyMemberViewController ()<UITableViewDataSource, UITableViewDelegate>
@property(strong,nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;
@property(strong, nonatomic)UITableView * tableView;
@property(strong, nonatomic)UIButton *barButton;
@property(strong, nonatomic)UIButton *loadMoreButton;
@property( nonatomic, readwrite) NSUInteger startInt;
@property(nonatomic, readwrite) BOOL isLOADMORE;
@end

@implementation CompanyMemberViewController
@synthesize companyID;
@synthesize sourceData;
@synthesize sourceDict;
@synthesize tableView;
@synthesize barButton;
@synthesize loadMoreButton;
@synthesize startInt;
@synthesize isLOADMORE;

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


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"公司成员列表");
	// Do any additional setup after loading the view.
    self.view.backgroundColor = BGCOLOR;
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height-44) style:UITableViewStylePlain];
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    self.tableView.separatorColor = SEPCOLOR;
    
    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    
    self.sourceData = [[NSArray alloc]init];
    self.startInt = 0;
    self.isLOADMORE = NO;

    
    // footerView
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 60)];
    
    self.loadMoreButton  = [[UIButton alloc] initWithFrame:CGRectMake(40, 10, 240, 40)];
    [self.loadMoreButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
    [self.loadMoreButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.loadMoreButton setTitleColor:RGBCOLOR(143, 183, 225) forState:UIControlStateHighlighted];
    [self.loadMoreButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
    [self.loadMoreButton setBackgroundColor:[UIColor clearColor]];
    //    [self.loadMoreButton.layer setBorderColor:[RGBCOLOR(187, 217, 247) CGColor]];
    //    [self.loadMoreButton.layer setBorderWidth:1.0f];
    [self.loadMoreButton.layer setCornerRadius:5.0f];
    [self.loadMoreButton addTarget:self action:@selector(loadMoreAction) forControlEvents:UIControlEventTouchUpInside];
    [self.loadMoreButton setHidden:YES];
    
    [self.tableView.tableFooterView addSubview:self.loadMoreButton];
    
    [self.view addSubview:self.tableView];
    

}


-(void)loadMoreAction
{
    self.isLOADMORE = YES;
    [self populateData:self.startInt];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.loadMoreButton setHidden:NO];
    [self.loadMoreButton setEnabled:YES];
    
    if (self.sourceData == nil || [self.sourceData count] == 0) {
        self.startInt = 0;
        [self populateData:self.startInt];
    }
}

// 解析公司成员列表
- (void)populateData:(NSUInteger)start
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载");
    
    
    [[AppNetworkAPIClient sharedClient]getCompanyMemberWithCompanyID:self.companyID andStart:start withBlock:^(id responseObject, NSError *error) {
        [HUD hide:YES];
        if (responseObject != nil) {
            
            NSMutableArray *allData = [[NSMutableArray alloc]initWithArray:self.sourceData];
            
            NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithDictionary:responseObject];
            
//            [responseDict removeObjectForKey:[self appDelegate].me.guid];  // 移出自己
            
            self.startInt += [responseDict count];
            
            if (self.isLOADMORE) {
                [responseDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [allData addObject:obj];
                }];
                
                self.sourceData = [[NSArray alloc]initWithArray:allData];
            }else{
                self.sourceData = [responseDict allValues];
            }
            
            
            // 数量太少不出现 load more
            if([responseDict count] == 0) {
                [self.loadMoreButton setTitle:T(@"没有更多了") forState:UIControlStateNormal];
            } else {
                [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
            }
            
            [self.tableView reloadData];
            
        }else{
            [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误 暂时无法刷新") andHideAfterDelay:1];
        }
        
        [self.loadMoreButton setEnabled:YES];
        [self.loadMoreButton setHidden:NO];
        self.isLOADMORE = NO;
    }];
    
    
    
    
//    [[AppNetworkAPIClient sharedClient]getCompanyMemberWithCompanyID:self.companyID andStart:start withBlock:^(id responseObject, NSError *error) {
//        //
//        [HUD hide:YES];
//        
//        if (responseObject != nil) {
//            NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithDictionary:responseObject];
//
//            [responseDict removeObjectForKey:[self appDelegate].me.guid];  // 移出自己
//
//            self.sourceDict = responseDict;
//            NSMutableArray *allData = [[NSMutableArray alloc]initWithArray:self.sourceData];
//            NSArray *timeData = [self.sourceDict allValues];
//            
//            for (int i = 0; i < [timeData count]; i++) {
//                [allData addObject: [timeData objectAtIndex:i]];
//            }
//            
//            
//            self.sourceData = [[NSArray alloc]initWithArray:allData];
//
//            [self.tableView reloadData];
//        }else{
//            DDLogVerbose(@"error %@",error);
//            if (error.code == 403) {
//                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"你还没有加入该公司") andHideAfterDelay:1];
//            }else{
//                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误 暂时无法刷新") andHideAfterDelay:1];
//            }
//        }
//    }];
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
    return [self.sourceData count];
}
#define CELL_HEIGHT 50.0f

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CompanyMemberListCell";
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];

    CompanyMemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[CompanyMemberTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setNewMember:dataDict];
    
    return cell;
}
/*

#define AVATAR_HEIGHT 36
#define AVATAR_X    (CELL_HEIGHT - AVATAR_HEIGHT)/2
#define NAME_X      75
#define NAME_HEIGHT 16
#define NAME_Y      (CELL_HEIGHT - NAME_HEIGHT)/2
#define NAME_WIDTH  200

#define COUNT_X     145
#define COUNT_WIDTH 130
#define COUNT_HEIGHT 21
#define COUNT_Y     (CELL_HEIGHT - COUNT_HEIGHT)/2

#define AVATAR_TAG  1
#define NAME_TAG    2
#define COUNT_TAG   3


- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"cell_H50_bg.png"]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    UIImageView *avatarView = [[UIImageView alloc]initWithFrame:CGRectMake(AVATAR_X*2, AVATAR_X, AVATAR_HEIGHT, AVATAR_HEIGHT)];
    [avatarView.layer setMasksToBounds:YES];
    [avatarView.layer setCornerRadius:3.0f];
    avatarView.tag = AVATAR_TAG;
    
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(NAME_X, NAME_Y, NAME_WIDTH, NAME_HEIGHT)];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.font = [UIFont systemFontOfSize:16.0f];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.textColor = RGBCOLOR(107, 107, 107);
    nameLabel.tag = NAME_TAG;
    
    UILabel *countLabel = [[UILabel alloc]initWithFrame:CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT)];
    countLabel.backgroundColor = [UIColor clearColor];
    countLabel.font = [UIFont systemFontOfSize:14.0f];
    countLabel.textAlignment = NSTextAlignmentRight;
    countLabel.textColor = LIVID_COLOR;
    countLabel.tag = COUNT_TAG;
    
    [cell addSubview:avatarView];
    [cell addSubview:nameLabel];
    [cell addSubview:countLabel];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    
    if ([[self appDelegate].me.guid isEqualToString:[dataDict objectForKey:@"guid"]]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
    UIImageView *avatarView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
    NSURL *url = [NSURL URLWithString:[dataDict objectForKey:@"thumbnail"]];
    [avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    nameLabel.text = [dataDict objectForKey:@"nickname"];
    
    UILabel *countLabel = (UILabel *)[cell viewWithTag:COUNT_TAG];
    countLabel.text = [dataDict objectForKey:@"signature"];
}
*/

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = BGCOLOR;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    // 自己不能点击
    if (![[self appDelegate].me.guid isEqualToString:[dataDict objectForKey:@"guid"]]) {
        [self getDict:[ServerDataTransformer getGUIDFromServerJSON:dataDict]];
    }

}

- (void)getDict:(NSString *)guidString
{
    
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
            //DDLogVerbose(@"nearby user get one received: %@", responseObject);
            
            [HUD hide:YES];
            NSString* type = [responseObject valueForKey:@"type"];
            if ([type isEqualToString:@"user"]) {
                ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
                controller.jsonData = responseObject;
                controller.managedObjectContext = [self appDelegate].context;
                controller.GUIDString = guidString;
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
