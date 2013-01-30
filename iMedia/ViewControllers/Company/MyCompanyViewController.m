//
//  MyCompanyViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-29.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "MyCompanyViewController.h"
#import "AppNetworkAPIClient.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"
#import "UIImageView+AFNetworking.h"
#import "CompanyDetailViewController.h"
#import "Company.h"
#import "ModelHelper.h"
#import "AppDelegate.h"
#import "DDLog.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface MyCompanyViewController ()<UITableViewDataSource,UITableViewDelegate>
@property(strong, nonatomic)UIButton *barButton;
@property(strong,nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;

@end

@implementation MyCompanyViewController
@synthesize barButton;
@synthesize sourceData;
@synthesize sourceDict;
@synthesize managedObjectContext;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed:@"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
    }
    return self;
}
- (void)mainMenuAction
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#define CELL_HEIGHT 50.0f

#define AVATAR_HEIGHT 36
#define AVATAR_X    (CELL_HEIGHT - AVATAR_HEIGHT)/2
#define NAME_X      75
#define NAME_HEIGHT 16
#define NAME_Y      (CELL_HEIGHT - NAME_HEIGHT)/2
#define NAME_WIDTH  200

#define COUNT_X     230
#define COUNT_WIDTH 15
#define COUNT_HEIGHT 15
#define COUNT_Y     (CELL_HEIGHT - COUNT_HEIGHT)/2

#define AVATAR_TAG  1
#define NAME_TAG    2
#define COUNT_TAG   3

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"我的公司");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.view.backgroundColor = BGCOLOR;
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    
    self.sourceData = [[NSArray alloc]init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self populateData];
    
    self.sourceData = [self getAllCompanyFromDB];
    [self.tableView reloadData];
}

// 解析公司列表
- (void)populateData
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载");
    [[AppNetworkAPIClient sharedClient]getMyCompanyWithBlock:^(id responseDict, NSError *error) {

        [HUD hide:YES];
        
        if (responseDict != nil) {
            self.sourceDict = responseDict;
            self.sourceData = [self.sourceDict allValues];
            [self.tableView reloadData];
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误 暂时无法刷新") andHideAfterDelay:1];
        }
    }];
}

- (NSArray *)getAllCompanyFromDB
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Company" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    // Set example predicate and sort orderings...
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:
//                              @"(status = %d)", CompanyStateFollowed];
//    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    if ([array count] == 0)
    {
        DDLogError(@"Company doesn't exist: %@", error);
        return nil;
    } else {
        return array;
    }
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
    return [self.sourceData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CompanyListCell";
    
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
    
    UIImageView *privateView = [[UIImageView alloc]initWithFrame:CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT)];
    [privateView setImage:[UIImage imageNamed:@"private_icon.png"]];
    privateView.tag = COUNT_TAG;
    
    [cell addSubview:avatarView];
    [cell addSubview:nameLabel];
    [cell addSubview:privateView];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Company *aCompany = [self.sourceData objectAtIndex:indexPath.row];
    
    UIImageView *avatarView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
    NSURL *url = [NSURL URLWithString:aCompany.logo];
    [avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    nameLabel.text = aCompany.name;
    
    UIImageView *privateView  = (UIImageView *)[cell viewWithTag:COUNT_TAG];
    if (aCompany.isPrivate.boolValue) {
        [privateView setHidden:NO];
    }else{
        [privateView setHidden:YES];
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = BGCOLOR;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Company *aCompany = [self.sourceData objectAtIndex:indexPath.row];
    
    NSString *companyID = aCompany.companyID;
    
    [self getDict:companyID];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getDict:(NSString *)companyID
{
    Company *aCompany = [[ModelHelper sharedInstance]findCompanyWithCompanyID:companyID];
    
    if (aCompany != nil && aCompany.status == CompanyStateFollowed ) {
        CompanyDetailViewController *controller = [[CompanyDetailViewController alloc]initWithNibName:nil bundle:nil];\
        controller.company = aCompany;
        controller.managedObjectContext = [self appDelegate].context;
        [self.navigationController pushViewController:controller animated:YES];
    }else {
        // get user info from web and display as if it is searched
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        HUD.labelText = T(@"正在加载");
        
        [[AppNetworkAPIClient sharedClient]getcompanyWithCompanyID:companyID withBlock:^(id responseDict, NSError *error) {
            //
            [HUD hide:YES];
            
            if (responseDict != nil) {
                CompanyDetailViewController *controller = [[CompanyDetailViewController alloc]initWithNibName:nil bundle:nil];\
                controller.jsonData = responseDict;
                controller.managedObjectContext = [self appDelegate].context;
                [self.navigationController pushViewController:controller animated:YES];
            }else{
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误 暂时无法刷新") andHideAfterDelay:1];
            }
            
        }];
    }
}



@end
