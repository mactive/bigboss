//
//  NearbyViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-15.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "NearbyViewController.h"
#import "AppNetworkAPIClient.h"
#import "MBProgressHUD.h"
#import "NearbyTableViewCell.h"
#import "EGORefreshTableHeaderView.h"

@interface NearbyViewController ()<MBProgressHUDDelegate,EGORefreshTableHeaderDelegate>
{
    EGORefreshTableHeaderView* refreshHeaderView;
    //  Reloading var should really be your tableviews datasource
    //  Putting it here for demo purposes
    BOOL _reloading;
    MBProgressHUD *HUD;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@property (nonatomic, strong) NSArray* sourceData;
@property (nonatomic, strong) UIView * headerView;
@property (nonatomic, strong) UIView * footerView;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (refreshHeaderView == nil) {
        EGORefreshTableHeaderView* view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height, 320.0f, 65.0)];
        view.delegate = self;
        [self.tableView addSubview:view];
        refreshHeaderView = view;
    }
    [refreshHeaderView refreshLastUpdatedDate];
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

    [[AppNetworkAPIClient sharedClient]getNearestPeopleWithBlock:^(id responseObject, NSError *error) {
        if (responseObject != nil) {
            NSDictionary *responseDict = responseObject;
            NSMutableArray *responseArray = [[NSMutableArray alloc]init];
            
            for (int j = 0; j < [responseDict count]; j++) {
                [responseArray insertObject:[responseObject objectForKey:[NSString stringWithFormat:@"%i",j]] atIndex:j];
            }
            self.sourceData = [[NSArray alloc] initWithArray:responseArray];
            
            [self.tableView reloadData];

        }else{
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.mode = MBProgressHUDModeText;
            HUD.delegate = self;
            HUD.labelText = T(@"网络错误 暂时无法刷新");
            [HUD hide:YES afterDelay:1];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview header and footer and fresh
//////////////////////////////////////////////////////////////////////////////////////////


#pragma mark - Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}


#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
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



@end
