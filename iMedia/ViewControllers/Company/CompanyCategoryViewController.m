//
//  CompanyCategoryViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-28.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "CompanyCategoryViewController.h"
#import "AppNetworkAPIClient.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "ServerDataTransformer.h"
#import "UIImageView+AFNetworking.h"
#import "CompanyListViewController.h"

@interface CompanyCategoryViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
@property(strong,nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;
@property(strong, nonatomic)UITableView * tableView;
@property(nonatomic, strong) UIButton *barButton;
@end

@implementation CompanyCategoryViewController
@synthesize sourceData;
@synthesize sourceDict;
@synthesize tableView;
@synthesize barButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"公司分类列表");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.view.backgroundColor = BGCOLOR;
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = BGCOLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.tableView.separatorColor = SEPCOLOR;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource  = self;
    [self.view addSubview:self.tableView];
    
    self.sourceData = [[NSArray alloc]init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self populateData];
}

// 解析公司列表
- (void)populateData
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载");
    [[AppNetworkAPIClient sharedClient]getCompanyCategoryWithBlock:^(id responseDict, NSError *error) {
        //
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return [self.sourceData count];
}
#define CELL_HEIGHT 50.0f

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CompanyCategoryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}
#define AVATAR_HEIGHT 36
#define AVATAR_X    (CELL_HEIGHT - AVATAR_HEIGHT)/2
#define NAME_X      75
#define NAME_HEIGHT 16
#define NAME_Y      (CELL_HEIGHT - NAME_HEIGHT)/2
#define NAME_WIDTH  80

#define COUNT_X     230
#define COUNT_WIDTH 33
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
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator ;

    
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
    
    UIImageView *countBG = [[UIImageView alloc]initWithFrame:CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT)];
    [countBG setImage:[UIImage imageNamed:@"countBg.png"]];
    
    UILabel *countLabel = [[UILabel alloc]initWithFrame:CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT)];
    countLabel.backgroundColor = [UIColor clearColor];
    countLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.textColor = RGBCOLOR(255, 255, 255);
    countLabel.tag = COUNT_TAG;
    
    [cell addSubview:avatarView];
    [cell addSubview:nameLabel];
    [cell addSubview:countBG];
    [cell addSubview:countLabel];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    
    UIImageView *avatarView = (UIImageView *)[cell viewWithTag:AVATAR_TAG];
    NSURL *url = [NSURL URLWithString:[dataDict objectForKey:@"logo"]];
    [avatarView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"company_face.png"]];
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:NAME_TAG];
    nameLabel.text = [dataDict objectForKey:@"vn"];
    
    UILabel *countLabel = (UILabel *)[cell viewWithTag:COUNT_TAG];
    countLabel.text = [ServerDataTransformer getStringObjFromServerJSON:dataDict byName:@"c"];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = BGCOLOR;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    CompanyListViewController *controller = [[CompanyListViewController alloc]initWithNibName:nil bundle:nil];
    controller.categoryName = [dataDict objectForKey:@"cn"];
    [self.navigationController pushViewController:controller animated:YES];

}

@end
