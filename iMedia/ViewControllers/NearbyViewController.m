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
#import "PullToRefreshView.h"

@interface NearbyViewController ()


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

- (void)viewDidLoad {
    [super viewDidLoad];
	
	pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tableView];
    [pull setDelegate:self];
    [self.tableView addSubview:pull];
	

}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    [self reloadTableData];
}

-(void) reloadTableData
{
    // call to reload your data
    [self populateData];
    [pull setState:PullToRefreshViewStateLoading];
    sleep(2);
    [pull finishedLoading];

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
//    return [self.sourceData count];
    return 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
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
    
//    cell.data = rowData;
    return cell;
}



@end
