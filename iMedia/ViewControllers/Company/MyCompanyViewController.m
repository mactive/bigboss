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
#import "CompanyTableViewCell.h"
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

#define CELL_HEIGHT 50.0f

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
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


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
    [self syncCompamnyData];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.sourceData = [self getAllCompanyFromDB];
    [self.tableView reloadData];
}

- (NSArray *)getAllCompanyFromDB
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Company" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(status = %d)", CompanyStateFollowed];
    [request setPredicate:predicate];
    
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

// 解析公司列表
- (void)syncCompamnyData
{
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载");
    [[AppNetworkAPIClient sharedClient]getMyCompanyWithBlock:^(id responseDict, NSError *error) {
        
        [HUD hide:YES];
        
        if (responseDict != nil) {
            self.sourceDict = responseDict;
            NSArray *resArray = [self.sourceDict allValues];
            [resArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSDictionary *responseDict = obj;

                Company *theCompany = [[ModelHelper sharedInstance]findCompanyWithCompanyID:[ServerDataTransformer getCompanyIDFromServerJSON:responseDict]];
                ////////////////////////////////////////////////////////////////////////////////////
                // insert
                if (theCompany == nil) {
                    Company *newCompany = [NSEntityDescription insertNewObjectForEntityForName:@"Company" inManagedObjectContext:self.managedObjectContext];
                    newCompany.owner = [self appDelegate].me;
                    newCompany.status = CompanyStateFollowed;
                    [[ModelHelper sharedInstance] populateCompany:newCompany withServerJSONData:responseDict];
                }
                // update youcompany
                else{
                    NSEntityDescription *entityDescription = [NSEntityDescription
                                                              entityForName:@"Company" inManagedObjectContext:self.managedObjectContext];
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    [request setEntity:entityDescription];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                              @"(companyID = %@)", theCompany.companyID];
                    [request setPredicate:predicate];
                    
                    NSError *error = nil;
                    NSArray *companyArray = [self.managedObjectContext executeFetchRequest:request error:&error];
                    
                    if ([companyArray count] > 0){
                        Company *aCompany = [companyArray objectAtIndex:0];
                        aCompany.status = CompanyStateFollowed;
                        [self.managedObjectContext save:nil];
                        DDLogVerbose(@"SYNC update company success %@",aCompany.companyID);
                    }
                    
                }
                ////////////////////////////////////////////////////////////////////////////////////
                
            }];
            
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
