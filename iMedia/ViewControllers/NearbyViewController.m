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
#import "LocationManager.h"


static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface NearbyViewController ()<MBProgressHUDDelegate,PullToRefreshViewDelegate,ChatWithIdentityDelegate,UIActionSheetDelegate>
{
	PullToRefreshView *pull;
    //  Reloading var should really be your tableviews datasource
    //  Putting it here for demo purposes
    MBProgressHUD *HUD;
}

@property (nonatomic, strong) CLLocationManager *locManager;
@property (nonatomic, strong) NSArray* sourceData;
@property (nonatomic, strong) UIButton *loadMoreButton;
@property (nonatomic, strong) UIActionSheet *filterActionSheet;
@property( nonatomic, readwrite) NSUInteger genderInt;
@property( nonatomic, readwrite) NSUInteger startInt;
@property (nonatomic, readwrite) BOOL isLOADMORE;
@end

@implementation NearbyViewController
@synthesize sourceData;
@synthesize filterActionSheet;
@synthesize locManager;
@synthesize genderInt;
@synthesize startInt;
@synthesize isLOADMORE;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UIButton *button1 = [[UIButton alloc] init];
        button1.frame=CGRectMake(0, 0, 50, 30);
        [button1 setBackgroundImage:[UIImage imageNamed: @"barbutton_gender.png"] forState:UIControlStateNormal];
        [button1 addTarget:self action:@selector(filterAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button1];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始全部并且 
    self.genderInt = 0;
    self.startInt = 0;
    self.isLOADMORE = NO;
    
    self.locManager = [[CLLocationManager alloc] init];

//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//    self.tableView.separatorColor = [UIColor whiteColor];
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
//    [self.loadMoreButton.layer setBorderColor:[RGBCOLOR(187, 217, 247) CGColor]];
//    [self.loadMoreButton.layer setBorderWidth:1.0f];
    [self.loadMoreButton.layer setCornerRadius:5.0f];
    [self.loadMoreButton addTarget:self action:@selector(loadMoreAction) forControlEvents:UIControlEventTouchUpInside];
    [self.loadMoreButton setHidden:YES];
    [self.tableView.tableFooterView addSubview:self.loadMoreButton];

}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    self.startInt = 0;
    [self populateDataWithGender:self.genderInt andStart:self.startInt];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // updateLocation self
#warning 如没有location 欢一个背景图  sourcedata = nil
    if ([LocationManager sharedInstance].isAllowed == NO) {
        // do sth here
    }
    
    if (self.sourceData == nil) {
        self.startInt = 0;
        [self populateDataWithGender:self.genderInt andStart:self.startInt];
    }
}

-(void)loadMoreAction
{
    [self populateDataWithGender:self.genderInt andStart:self.startInt];
    self.isLOADMORE = YES;
}

- (void)populateDataWithGender:(NSUInteger)gender andStart:(NSUInteger)start
{
    [self.loadMoreButton setTitle:T(@"正在载入") forState:UIControlStateNormal];

    [[AppNetworkAPIClient sharedClient]getNearestPeopleWithGender:gender andStart:start andBlock:^(id responseObject, NSError *error) {
        if (responseObject != nil) {
            
            // pull view hide
            [pull finishedLoading];

            BOOL t1 = self.isLOADMORE;
            NSInteger t2 = gender;
            NSInteger t3 = start;
            
            
            NSDictionary *responseDict = responseObject;
            NSMutableArray *responseArray = [[NSMutableArray alloc]init];
            if ([responseDict count] > 0) {
                [self.loadMoreButton setTitle:T(@"点击加载更多") forState:UIControlStateNormal];
                if (self.isLOADMORE == YES) {
                    self.isLOADMORE = NO;
                    
                    responseArray = [[NSMutableArray alloc]initWithArray:self.sourceData];
                    NSUInteger sCount = [self.sourceData count];
                    for (int j = sCount; j < [responseDict count]+sCount; j++) {
                        [responseArray insertObject:[responseObject objectForKey:[NSString stringWithFormat:@"%i",j]] atIndex:j];
                    }
                }else{
                    for (int j = 0; j < [responseDict count]; j++) {
                        [responseArray insertObject:[responseObject objectForKey:[NSString stringWithFormat:@"%i",j]] atIndex:j];
                    }
                }
                
                self.sourceData = [[NSArray alloc] initWithArray:responseArray];
                // 重新设置start
                self.startInt = [self.sourceData count];
                
                // 数量太少不出现 load more
                if([self.sourceData count] > 4) {   [self.loadMoreButton setHidden:NO]; }
                
                
                [self.tableView reloadData];
            }else{
                [self.loadMoreButton setTitle:T(@"没有更多了") forState:UIControlStateNormal];
            }
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
#pragma mark - action sheet
//////////////////////////////////////////////////////////////////////////////////////////
- (void)filterAction
{
    self.filterActionSheet = [[UIActionSheet alloc]
                              initWithTitle:T(@"筛选附近的人")
                              delegate:self
                              cancelButtonTitle:T(@"取消")
                              destructiveButtonTitle:T(@"查看全部")
                              otherButtonTitles:T(@"只看女生"), T(@"只看男生"), nil];
    self.filterActionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [self.filterActionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
}


/////////////////////////////////////////////
#pragma mark - uiactionsheet delegate
////////////////////////////////////////////
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([self.filterActionSheet isEqual:actionSheet] ) {
        
        if (buttonIndex == 0) {
            DDLogVerbose(@"查看全部");
            self.genderInt = 0;
            self.startInt  = 0;
            self.title = T(@"附近");
        } else if (buttonIndex == 1) {
            self.genderInt = 2;
            self.startInt  = 0;
            DDLogVerbose(@"查看女生");
            self.title = T(@"附近(女)");
        } else if (buttonIndex == 2){
            DDLogVerbose(@"查看男生");
            self.genderInt = 1;
            self.startInt  = 0;
            self.title = T(@"附近(男)");
        }
        
        [self populateDataWithGender:self.genderInt andStart:self.startInt];
    
    }
    
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
