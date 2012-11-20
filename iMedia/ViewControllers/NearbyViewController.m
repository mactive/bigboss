//
//  NearbyViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-15.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "NearbyViewController.h"
#import "AppNetworkAPIClient.h"
#import "DDLog.h"
#import "MBProgressHUD.h"
#import "NearbyTableViewCell.h"
#import "PullToRefreshView.h"
#import "ContactDetailController.h"
#import "AppDelegate.h"
#import "ConversationsController.h"
#import "User.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface NearbyViewController ()<MBProgressHUDDelegate,PullToRefreshViewDelegate,ChatWithIdentityDelegate>
{
	PullToRefreshView *pull;
    //  Reloading var should really be your tableviews datasource
    //  Putting it here for demo purposes
    MBProgressHUD *HUD;
}


@property (nonatomic, strong) NSArray* sourceData;
@property (nonatomic, strong) UIButton *loadMoreButton;
@end

@implementation NearbyViewController
@synthesize sourceData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = BGCOLOR;
	
	pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tableView];
    [pull setDelegate:self];
    [self.tableView addSubview:pull];
    
    // footerView
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 60)];
    
    self.loadMoreButton  = [[UIButton alloc] initWithFrame:CGRectMake(40, 10, 240, 40)];
    [self.loadMoreButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [self.loadMoreButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.loadMoreButton setTitleColor:RGBCOLOR(143, 183, 225) forState:UIControlStateHighlighted];
    [self.loadMoreButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
    [self.loadMoreButton setBackgroundColor:RGBCOLOR(229, 240, 251)];
    [self.loadMoreButton.layer setBorderColor:[RGBCOLOR(187, 217, 247) CGColor]];
    [self.loadMoreButton.layer setBorderWidth:1.0f];
    [self.loadMoreButton.layer setCornerRadius:5.0f];
    [self.loadMoreButton addTarget:self action:@selector(populateData) forControlEvents:UIControlEventTouchUpInside];
    [self.loadMoreButton setHidden:YES];
    [self.tableView.tableFooterView addSubview:self.loadMoreButton];

}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    [self populateData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.sourceData == nil) {
        [self populateData];
    }
}

- (void)populateData
{
    [self.loadMoreButton setTitle:T(@"正在载入") forState:UIControlStateNormal];

    [[AppNetworkAPIClient sharedClient]getNearestPeopleWithBlock:^(id responseObject, NSError *error) {
        if (responseObject != nil) {
            
            // pull view hide
            [pull finishedLoading];
            [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];

            NSDictionary *responseDict = responseObject;
            NSMutableArray *responseArray = [[NSMutableArray alloc]init];
            
            for (int j = 0; j < [responseDict count]; j++) {
                [responseArray insertObject:[responseObject objectForKey:[NSString stringWithFormat:@"%i",j]] atIndex:j];
            }
            self.sourceData = [[NSArray alloc] initWithArray:responseArray];
            
            if([self.sourceData count] > 5) {   [self.loadMoreButton setHidden:NO]; }
            
            [self.tableView reloadData];

        }else{
            [pull finishedLoading];
            [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];

            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.mode = MBProgressHUDModeText;
            HUD.delegate = self;
            HUD.labelText = T(@"网络错误 暂时无法刷新");
            [HUD hide:YES afterDelay:1];
        }
    }];
}



//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview header and footer and fresh
//////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview delegate
//////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sourceData count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview datasource
//////////////////////////////////////////////////////////////////////////////////////////

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NearbyCell";
    
    NSDictionary *rowData = [self.sourceData objectAtIndex:indexPath.row];
    
    NearbyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[NearbyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.data = rowData;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *rowData = [self.sourceData objectAtIndex:indexPath.row];
    [self getDict:[rowData objectForKey:@"guid"]];
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getDict:(NSString *)guidString
{
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: guidString, @"guid", @"1", @"op", nil];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = T(@"正在请求");
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get config JSON received: %@", responseObject);
        
        [HUD hide:YES];
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"]) {            
            ContactDetailController *controller = [[ContactDetailController alloc] initWithNibName:nil bundle:nil];
            controller.jsonData = responseObject;
            controller.GUID = guidString;
            controller.managedObjectContext = [self appDelegate].context;
            
            // Pass the selected object to the new view controller.
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
        [HUD hide:YES];
        
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.mode = MBProgressHUDModeText;
        HUD.delegate = self;
        HUD.labelText = T(@"网络错误，无法获取用户数据");
        [HUD hide:YES afterDelay:1];
    }];
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors & selectors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewController:(UIViewController *)viewController didChatIdentity:(id)obj
{
    [self dismissModalViewControllerAnimated:YES];
    
    if (obj) {
        [self.tabBarController setSelectedIndex:1];
        [[self appDelegate].conversationController chatWithIdentity:obj];
    }
    
}


@end
