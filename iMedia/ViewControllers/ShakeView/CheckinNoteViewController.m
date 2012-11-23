//
//  CheckinNoteViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-23.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "CheckinNoteViewController.h"
#import "AppNetworkAPIClient.h"

@interface CheckinNoteViewController ()
@property(nonatomic, strong)NSArray *dataArray;

@end

@implementation CheckinNoteViewController
@synthesize dataArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;
}

NSInteger intSort(id num1, id num2, void *context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.title = T(@"连续签到奖励");

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[AppNetworkAPIClient sharedClient]getCheckinInfoWithBlock:^(id responseObject, NSError *error) {
        if (responseObject) {
            NSDictionary *responseDict = responseObject;
            NSDictionary *item = [[NSDictionary alloc]init];
            NSMutableArray *tempArray = [[NSMutableArray alloc]init];
            NSArray *keyArray = [[responseDict allKeys] sortedArrayUsingFunction:intSort context:NULL];
            
            for (int j = 0;  j< [keyArray count]; j++) {
                NSString * KEY = [keyArray objectAtIndex:j];
                item = [[NSDictionary alloc]initWithObjectsAndKeys:KEY,@"day",[responseDict objectForKey:KEY] ,@"reward", nil];
                [tempArray insertObject:item atIndex:j];
            }
            self.dataArray  = tempArray;
        }
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
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
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CheckinCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIImageView *cellBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bg.png"]];
        cell.backgroundView = cellBgView;
        NSDictionary *data = [self.dataArray objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"第 %@ 天 - %@" ,[data objectForKey:@"day"],[data objectForKey:@"reward"]];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    }

    
    return cell;
}

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
