//
//  MainMenuViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-24.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "MainMenuViewController.h"
#import "MetroButton.h"
#import <QuartzCore/QuartzCore.h>
#import "AppNetworkAPIClient.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import "AppDelegate.h"
#import "ModelHelper.h"
#import "ServerDataTransformer.h"
#import "Me.h"
#import "Company.h"
#import "CompanyDetailViewController.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
@interface MainMenuViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UITextFieldDelegate>

@property(nonatomic, strong)NSArray *menuTitleArray;
@property(strong, nonatomic)UIView *menuView;
@property(strong, nonatomic)CATransition* transition;
@property(strong, nonatomic)UISearchBar *searchBar;
@property(strong, nonatomic)UIButton *barButton;
@property(strong, nonatomic)UIButton *lastMessageButton;
@property(strong, nonatomic)UIButton *settingButton;
@property(strong, nonatomic)UITableView *searchTableView;
@property(strong, nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableArray *fetchArray;
@property(strong, nonatomic)NSMutableDictionary *fetchDict;
@property(strong, nonatomic)NSMutableArray *buttonArray;
@end

@implementation MainMenuViewController
@synthesize menuTitleArray;
@synthesize menuView;
@synthesize transition;
@synthesize searchTableView;
@synthesize searchBar;
@synthesize barButton;
@synthesize lastMessageButton;
@synthesize settingButton;
@synthesize sourceData;
@synthesize fetchArray;
@synthesize fetchDict;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize buttonArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_bg.png"] forState:UIControlStateNormal];
        [self.barButton setTitle:T(@"返回") forState:UIControlStateNormal];
        [self.barButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
        [self.barButton addTarget:self action:@selector(cancelSearchAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        
        
        self.settingButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 29)];
        [self.settingButton setBackgroundImage:[UIImage imageNamed: @"barbutton_setting.png"] forState:UIControlStateNormal];
        [self.settingButton addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];

        self.lastMessageButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 29)];
        [self.lastMessageButton addTarget:self action:@selector(lastMessageAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.settingButton];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.lastMessageButton];


    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#define VIEW_OFFSET 5
#define VIEW_WIDTH 310
#define HALF_WIDTH (VIEW_WIDTH-VIEW_OFFSET)/2

- (CGRect)calcRect:(NSInteger)index
{
    DDLogVerbose(@"self.view.bounds.size.height %f",self.view.bounds.size.height);
    CGFloat liteHeight = self.view.bounds.size.height / 460 * 45;
    CGFloat halfHeight = self.view.bounds.size.height / 460 * HALF_WIDTH;
    DDLogVerbose(@"%f",self.view.bounds.size.height);
    CGRect rect = CGRectZero;
    switch (index) {
        case 0:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET, VIEW_WIDTH , liteHeight);
            break;
        case 1:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET*2+liteHeight, HALF_WIDTH, halfHeight);
            break;
        case 2:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET*2+liteHeight, HALF_WIDTH, halfHeight);
            break;
        case 3:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET*3+liteHeight+halfHeight, HALF_WIDTH, halfHeight+liteHeight);
            break;
        case 4:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET*3+liteHeight+halfHeight, HALF_WIDTH, (halfHeight-15));
            break;
        case 5:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET+liteHeight+halfHeight*2, HALF_WIDTH, liteHeight+10);
            break;
        default:
            rect = CGRectZero;
            break;
    }
    
    return rect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = T(@"大掌柜");
    self.menuTitleArray = [[NSArray alloc] initWithObjects:@"搜索公司",@"消息",@"联系人",@"福利",@"我的公司",@"公司列表", nil];
    self.view.backgroundColor = BGCOLOR;
    [self.view addSubview:self.menuView];
    self.buttonArray = [[NSMutableArray alloc]init];
    for (int index = 0; index <[self.menuTitleArray count]; index++) {
        MetroButton *button = [[MetroButton alloc]initWithFrame:[self calcRect:index]];
        NSString *title = [self.menuTitleArray objectAtIndex:index];
        NSString *image = [NSString stringWithFormat:@"main_menu_icon_%d.png",index];
        [button initMetroButton:[UIImage imageNamed:image] andText:title andIndex:index];
        
        if (index == 0) {
            [button addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 1) {
            [button addTarget:self action:@selector(conversationAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 2) {
            [button addTarget:self action:@selector(contactAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 3) {
            [button addTarget:self action:@selector(functionAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 4) {
            [button addTarget:self action:@selector(myCompanyAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 5) {
            [button addTarget:self action:@selector(companyCategoryAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
        [self.buttonArray addObject:button];
    }
    
    // init all viewcontroller
    [self initViewControllers];
    [self initSearchTableView];
    // transition animation
    self.transition = [CATransition animation];
    self.transition.duration = 0.1;
    self.transition.type = kCATransitionFade;
    self.transition.timingFunction = UIViewAnimationCurveEaseInOut;
    self.transition.subtype = kCATransitionFromLeft;
    self.fetchArray = [[NSMutableArray alloc]init];
    self.fetchDict = [[NSMutableDictionary alloc]init];
    
//  update company
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //;
    if (self.searchTableView.hidden == NO) {
        [self cancelSearchAction];
    }
    
    // 为了消息数量计算使用
    NSInteger badgeInt = [[self appDelegate].conversationController updateMainMenuUnreadBadge];
    
    MetroButton *targetButton = [self.buttonArray objectAtIndex:1];
    [targetButton setBadgeNumber:badgeInt];
    
}
- (void)updateLastMessageWithCount:(NSUInteger)lastMessageCount
{
    if (lastMessageCount > 0) {
        NSString *lastMessageCountString  = [NSString stringWithFormat:@"%d",lastMessageCount];
        [self.lastMessageButton setTitle:lastMessageCountString forState:UIControlStateNormal];
        [self.lastMessageButton setTitleEdgeInsets:UIEdgeInsetsMake(8, 23, 8, 8)];
        [self.lastMessageButton setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        [self.lastMessageButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [self.lastMessageButton.titleLabel setShadowColor:[UIColor blackColor]];
        [self.lastMessageButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
        [self.lastMessageButton setBackgroundImage:[UIImage imageNamed: @"barbutton_notification_100.png"] forState:UIControlStateNormal];
    }else{
        [self.lastMessageButton setTitle:nil forState:UIControlStateNormal];
        [self.lastMessageButton  setBackgroundImage:[UIImage imageNamed: @"barbutton_notification.png"] forState:UIControlStateNormal];
    }
}

- (void)initViewControllers
{
    [self appDelegate].conversationController = [[ConversationsController alloc] initWithStyle:UITableViewStylePlain];
    [self appDelegate].conversationController.managedObjectContext = self.managedObjectContext;
    
    
    [self appDelegate].contactListController = [[ContactListViewController alloc] initWithStyle:UITableViewStylePlain andManagementContext:self.managedObjectContext];
    
    [self appDelegate].shakeDashboardViewController = [[ShakeDashboardViewController alloc]initWithNibName:nil bundle:nil];
    [self appDelegate].shakeDashboardViewController.managedObjectContext = self.managedObjectContext;
    
    [self appDelegate].settingViewController = [[SettingViewController alloc]initWithNibName:nil bundle:nil];
    [self appDelegate].settingViewController.managedObjectContext = self.managedObjectContext;
    
    [self appDelegate].companyCategoryViewController = [[CompanyCategoryViewController alloc] initWithNibName:nil bundle:nil];
    
    [self appDelegate].myCompanyController = [[MyCompanyViewController alloc]initWithStyle:UITableViewStylePlain];
    [self appDelegate].myCompanyController.managedObjectContext = self.managedObjectContext;
    
    [self appDelegate].memoViewController = [[MemoViewController alloc]initWithNibName:nil bundle:nil];
    [self appDelegate].memoViewController.managedObjectContext = self.managedObjectContext;

}

- (void)initSearchTableView
{
    // uisearchbar
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    self.searchBar.delegate = self;
    self.searchBar.tintColor = RGBCOLOR(170, 170, 170);
    self.searchBar.showsCancelButton = YES;
    self.searchBar.placeholder = T(@"搜索公司");

    UIButton *cancelButton = nil;
    for(id subView in self.searchBar.subviews){
        if([subView isKindOfClass:[UIButton class]]){
            cancelButton = (UIButton*)subView;
        }
    }
    [cancelButton setTitle:@"搜索" forState:UIControlStateNormal];
    
    // table
    self.sourceData = [[NSArray alloc]init];
    self.searchTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.searchTableView];
    self.searchTableView.dataSource = self;
    self.searchTableView.delegate = self;
    self.searchTableView.tableHeaderView = self.searchBar;

    [self.searchTableView setHidden:YES];
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark populatedata
//////////////////////////////////////////////////////////////////////////////////////////

- (void)populateData:(NSString *)keyword
{
    [self.searchBar resignFirstResponder];
    
    MBProgressHUD* HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.labelText = T(@"正在加载");
    
    [[AppNetworkAPIClient sharedClient]getCompanyWithName:keyword withBlock:^(id responseDict, NSError *error) {
        //
        [HUD hide:YES];

        if (responseDict != nil) {
            if([responseDict count] == 0) {
                [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"没有符合的数据") andHideAfterDelay:1];
                self.sourceData = [[NSArray alloc]init];
                [self.searchTableView reloadData];
            }else{
                self.fetchDict = responseDict;
                self.sourceData = [self.fetchDict allValues];
                [self.searchTableView reloadData];
            }
        }else{
            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"网络错误 暂时无法刷新") andHideAfterDelay:1];
        }
    }];
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark uisearchbar delegate
//////////////////////////////////////////////////////////////////////////////////////////
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@",searchBar.text);
    if (StringHasValue(searchBar.text)) {
        // post to search to display
        [self populateData:searchBar.text];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    DDLogVerbose(@"%@",searchBar.text);
    if (StringHasValue(searchBar.text)) {
        // post to search to display
        [self populateData:searchBar.text];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark tablevie delegate
//////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sourceData count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CompanySearchCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];

    return cell;
}
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    cell.textLabel.text = [dataDict objectForKey:@"company_name"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    NSString *companyID = [ServerDataTransformer getCompanyIDFromServerJSON:dataDict];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//选中后的反显颜色即刻消失

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

//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark actions
//////////////////////////////////////////////////////////////////////////////////////////
- (void)searchAction
{
    [self.searchTableView setHidden:NO];
    [self.searchTableView.layer addAnimation:self.transition forKey:kCATransition];

    [self.searchBar becomeFirstResponder];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)cancelSearchAction
{
    [self.searchTableView setHidden:YES];
    [self.searchTableView.layer addAnimation:self.transition forKey:kCATransition];

    [self.searchBar resignFirstResponder];
    self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc]initWithCustomView:self.lastMessageButton];
    self.navigationItem.leftBarButtonItem   = [[UIBarButtonItem alloc]initWithCustomView:self.settingButton];
}

- (void)conversationAction{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].conversationController animated:NO];
}

- (void)contactAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].contactListController animated:NO];
}

- (void)functionAction
{

    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].shakeDashboardViewController animated:NO];
}
- (void)settingAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].settingViewController animated:NO];
}
- (void)companyCategoryAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].companyCategoryViewController animated:NO];
}
- (void)myCompanyAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].myCompanyController animated:NO];
}

- (void)lastMessageAction
{
    [self updateLastMessageWithCount:0];
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:[self appDelegate].memoViewController animated:NO];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
