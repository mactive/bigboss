//
//  CompanyListViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-24.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "CompanyListViewController.h"
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
#import "CompanyTableViewCell.h"

@interface CompanyListViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(strong,nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;
@property(strong, nonatomic)UITableView * tableView;

@end

@implementation CompanyListViewController
@synthesize sourceData;
@synthesize sourceDict;
@synthesize tableView;
@synthesize categoryName;
@synthesize codeName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.categoryName;
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
    [self populateData];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

// 解析公司列表
- (void)populateData
{
    [[AppNetworkAPIClient sharedClient]getCompanyWithCategory:self.codeName withBlock:^(id responseDict, NSError *error) {
        //
        
        if (responseDict != nil) {
            self.sourceDict = responseDict;
            NSArray *tempArray = [self.sourceDict allValues];
            NSMutableArray *tempMutableArray = [[NSMutableArray alloc]init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Company" inManagedObjectContext:[self appDelegate].context];
            
            for (int i=0; i < [tempArray count]; i++) {
                NSDictionary *dict = [tempArray objectAtIndex:i];
                Company *aCompany = [[ModelHelper sharedInstance] findCompanyWithCompanyID:[dict objectForKey:@"cid"] ];
                if (aCompany == nil) {
                    aCompany = (Company *)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
                    [[ModelHelper sharedInstance] populateCompany:aCompany withServerJSONData:dict];
                }
                
                [tempMutableArray addObject:aCompany];
            }
            
            
            self.sourceData = [[NSArray alloc]initWithArray:tempMutableArray];
            
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
    static NSString *CellIdentifier = @"CompanyListCell";
    
    Company *aCompany = [self.sourceData objectAtIndex:indexPath.row];

    
    CompanyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[CompanyTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setNewCompany:aCompany];
    
    return cell;
}


- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = BGCOLOR;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Company *aCompany = [self.sourceData objectAtIndex:indexPath.row];
    
    [self getDict:aCompany.companyID];
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getDict:(NSString *)companyID
{
    Company *aCompany = [[ModelHelper sharedInstance]findCompanyWithCompanyID:companyID];
    
    if (aCompany != nil && aCompany.status == CompanyStateFollowed ) {
        CompanyDetailViewController *controller = [[CompanyDetailViewController alloc]initWithNibName:nil bundle:nil];
        controller.company = aCompany;
        controller.managedObjectContext = [self appDelegate].context;
        [self.navigationController pushViewController:controller animated:YES];
    }else {
        // get user info from web and display as if it is searched
        MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.removeFromSuperViewOnHide = YES;
        HUD.labelText = T(@"正在加载");

        [[AppNetworkAPIClient sharedClient]getCompanyWithCompanyID:companyID withBlock:^(id responseDict, NSError *error) {
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
