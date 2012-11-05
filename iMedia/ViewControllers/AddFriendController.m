//
//  AddFriendController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/12/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AddFriendController.h"
#import "AddFriendByIDController.h"

@interface AddFriendController ()

@end

@implementation AddFriendController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"AddFriend";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setBackgroundColor:[UIColor clearColor]];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AddFriendCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    
    return cell;
}
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

    cell.backgroundView.backgroundColor = [UIColor whiteColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UIImageView *iconImage = [[UIImageView alloc]initWithFrame:CGRectMake(24, 15, 20, 20)];
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 15, 140, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(77, 77, 77);
    titleLabel.backgroundColor = [UIColor clearColor];
    
    // Configure the cell...
    if (indexPath.row == 0) {
        // search cell
        [iconImage setImage:[UIImage imageNamed:@"add_icon.png"]];
        titleLabel.text = T(@"搜索用户名,用户ID");
    } else if (indexPath.row == 1) {
        //test cell
        [iconImage setImage:[UIImage imageNamed:@"contact_icon.png"]];
        titleLabel.text = T(@"从通讯录中添加");
    }
    
    [cell addSubview:iconImage];
    [cell addSubview:titleLabel];
    
    return cell;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
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
    if (indexPath.section == 0) {
        // add friend by search ID
        AddFriendByIDController *controller = [[AddFriendByIDController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:controller animated:YES];
    }
    // Navigation logic may go here. Create and push another view controller.
    /*
       *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
