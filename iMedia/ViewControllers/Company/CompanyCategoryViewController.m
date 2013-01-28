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

@interface CompanyCategoryViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
@property(strong,nonatomic)NSArray *sourceData;
@property(strong, nonatomic)NSMutableDictionary * sourceDict;
@property(strong, nonatomic)UITableView * tableView;
@end

@implementation CompanyCategoryViewController
@synthesize sourceData;
@synthesize sourceDict;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
    
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
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = SEPCOLOR;
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
#define NAME_Y      15
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
    
    UIImageView *avatarView = [[UIImageView alloc]initWithFrame:CGRectMake(AVATAR_X, AVATAR_X, AVATAR_HEIGHT, AVATAR_HEIGHT)];
    avatarView.tag = AVATAR_TAG;
    
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(NAME_X, NAME_Y, NAME_WIDTH, NAME_Y)];
    nameLabel.tag = NAME_TAG;
    
    UIImageView *countBG = [[UIImageView alloc]initWithFrame:CGRectMake(COUNT_X, COUNT_Y, COUNT_WIDTH, COUNT_HEIGHT)];
    [countBG setImage:[UIImage imageNamed:@"countBg.png"]];
    
    UILabel *countLabel = [[UILabel alloc]initWithFrame:CGRectMake(NAME_X, NAME_Y, NAME_WIDTH, NAME_Y)];
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
    
    
    
    cell.textLabel.text = [dataDict objectForKey:@"vn"];
    cell.detailTextLabel.text = [ServerDataTransformer getStringObjFromServerJSON:dataDict byName:@"c"];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
