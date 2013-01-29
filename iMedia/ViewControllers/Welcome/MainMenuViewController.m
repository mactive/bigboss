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
@property(strong, nonatomic)UITableView *searchTableView;
@property(strong, nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableArray *fetchArray;
@property(strong, nonatomic)NSMutableDictionary *fetchDict;
@end

@implementation MainMenuViewController
@synthesize menuTitleArray;
@synthesize menuView;
@synthesize conversationController;
@synthesize contactListViewController;
@synthesize functionListViewController;
@synthesize settingViewController;
@synthesize companyCategoryViewController;
@synthesize transition;
@synthesize searchTableView;
@synthesize searchBar;
@synthesize barButton;
@synthesize sourceData;
@synthesize fetchArray;
@synthesize fetchDict;
@synthesize managedObjectContext = _managedObjectContext;

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
    }
    return self;
}

#define VIEW_OFFSET 5
#define VIEW_WIDTH 310
#define HALF_WIDTH (VIEW_WIDTH-VIEW_OFFSET)/2
#define LITE_HEIGHT 45

- (CGRect)calcRect:(NSInteger)index
{
    CGRect rect = CGRectZero;
    switch (index) {
        case 0:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET, VIEW_WIDTH , LITE_HEIGHT);
            break;
        case 1:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET*2+LITE_HEIGHT, HALF_WIDTH, HALF_WIDTH);
            break;
        case 2:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET*2+LITE_HEIGHT, HALF_WIDTH, HALF_WIDTH);
            break;
        case 3:
            rect = CGRectMake(VIEW_OFFSET, VIEW_OFFSET*3+LITE_HEIGHT+HALF_WIDTH, HALF_WIDTH, HALF_WIDTH+LITE_HEIGHT);
            break;
        case 4:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET*3+LITE_HEIGHT+HALF_WIDTH, HALF_WIDTH, (HALF_WIDTH-15));
            break;
        case 5:
            rect = CGRectMake(VIEW_OFFSET*2 + HALF_WIDTH, VIEW_OFFSET+LITE_HEIGHT+HALF_WIDTH*2, HALF_WIDTH, LITE_HEIGHT+10);
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
    self.menuTitleArray = [[NSArray alloc] initWithObjects:@"搜索公司",@"消息",@"联系人",@"福利",@"设置",@"公司列表", nil];
    self.view.backgroundColor = BGCOLOR;
    [self.view addSubview:self.menuView];
    
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
            [button addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 5) {
            [button addTarget:self action:@selector(companyAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
    }
    
    // init all viewcontroller
    [self initViewControllers];
    [self initSearchTableView];
    // transition animation
    self.transition = [CATransition animation];
    self.transition.duration = 0.3;
    self.transition.type = kCATransitionFade;
    self.transition.timingFunction = UIViewAnimationCurveEaseInOut;
    self.transition.subtype = kCATransitionFromLeft;
    self.fetchArray = [[NSMutableArray alloc]init];
    self.fetchDict = [[NSMutableDictionary alloc]init];
}

- (void)initViewControllers
{
    self.conversationController = [[ConversationsController alloc] initWithStyle:UITableViewStylePlain];
    self.conversationController.managedObjectContext = self.managedObjectContext;
    
    self.contactListViewController = [[ContactListViewController alloc] initWithStyle:UITableViewStylePlain andManagementContext:self.managedObjectContext];
    
    self.functionListViewController = [[FunctionListViewController alloc]initWithNibName:nil bundle:nil];
    self.functionListViewController.managedObjectContext = self.managedObjectContext;
    
    self.settingViewController = [[SettingViewController alloc]initWithNibName:nil bundle:nil];
    self.settingViewController.managedObjectContext = self.managedObjectContext;
    
    self.companyCategoryViewController = [[CompanyCategoryViewController alloc] initWithNibName:nil bundle:nil];
}

- (void)initSearchTableView
{
    // uisearchbar
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dataDict = [self.sourceData objectAtIndex:indexPath.row];
    cell.textLabel.text = [dataDict objectForKey:@"company_name"];

}
//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark actions
//////////////////////////////////////////////////////////////////////////////////////////
- (void)searchAction
{
    [self.searchTableView setHidden:NO];
    [self.searchBar becomeFirstResponder];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
}

- (void)cancelSearchAction
{
    [self.searchTableView setHidden:YES];
    [self.searchBar resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)conversationAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:self.conversationController animated:NO];
}

- (void)contactAction
{

    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:self.contactListViewController animated:NO];
    
}

- (void)functionAction
{

    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:self.functionListViewController animated:NO];
}
- (void)settingAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:self.settingViewController animated:NO];
}
- (void)companyAction
{
    [self.navigationController.view.layer addAnimation:self.transition forKey:kCATransition];
    [self.navigationController pushViewController:self.companyCategoryViewController animated:NO];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
