//
//  FunctionListViewController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/29/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FunctionListViewController.h"
#import "ShakeViewController.h"
#import "XMPPNetworkCenter.h"
#import "AppNetworkAPIClient.h"
#import "AppDelegate.h" 
#import "RequestViewController.h"
#import "FriendRequestListViewController.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface FunctionListViewController () <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) UITableView *settingTableView;

@property(nonatomic, strong) NSArray *settingTitleArray;
@property(nonatomic, strong) NSArray *settingDescArray;

@end

@implementation FunctionListViewController

@synthesize settingTableView;
@synthesize settingDescArray;
@synthesize settingTitleArray;
@synthesize friendRequestDict;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.friendRequestDict = [NSMutableDictionary dictionaryWithCapacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(friendRequestReceived:)
                                                     name:NEW_FRIEND_NOTIFICATION object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:
                              [[NSArray alloc] initWithObjects:@"附近的人", nil],
                              [[NSArray alloc] initWithObjects:@"打招呼的人", nil],
                              [[NSArray alloc] initWithObjects:@"摇一摇", nil],
                              nil ];
    
    
    
    self.settingTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.settingTableView.dataSource = self;
    self.settingTableView.delegate = self;
    //    [self.settingTableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.settingTableView];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableview
////////////////////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.settingTitleArray count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.settingTitleArray objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [self tableViewCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    }
    return cell;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - tableViewCellWithReuseIdentifier
////////////////////////////////////////////////////////////////////////////////

#define SUMMARY_WIDTH 200
#define LABEL_HEIGHT 20

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, message, and quarter image of the time zone.
	 */
    
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    cell.backgroundView.backgroundColor = RGBCOLOR(248, 248, 248);
    
    cell.selectedBackgroundView.backgroundColor =  RGBCOLOR(228, 228, 228);
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 140, 20)];
    titleLabel.text = [[self.settingTitleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    titleLabel.textColor = RGBCOLOR(77, 77, 77);
    titleLabel.backgroundColor = [UIColor clearColor];
    [cell addSubview:titleLabel];
    //    cell.textLabel.text = [self.infoArray objectAtIndex:indexPath.row];
    //    cell.textLabel.textColor = RGBCOLOR(155, 161, 172);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0 && indexPath.section == 1 ) {

        if ([self.friendRequestDict count] == 1) { 
            RequestViewController *controller = [[RequestViewController alloc] initWithNibName:nil bundle:nil];
            controller.jsonData = [[self.friendRequestDict allValues] objectAtIndex:0];
            [self.navigationController pushViewController:controller animated:YES];
            
//            FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
//            controller.friendRequestJSONArray = [NSMutableArray arrayWithArray:[self.friendRequestDict allValues]];
//            [self.navigationController pushViewController:controller animated:YES];
            
        } else if ([self.friendRequestDict count] > 1) {
            FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
            controller.friendRequestJSONArray = [NSMutableArray arrayWithArray:[self.friendRequestDict allValues]];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
    
    if (indexPath.row == 0 && indexPath.section == 2 ) {
        ShakeViewController *shakeViewController = [[ShakeViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:shakeViewController animated:YES];
    }
}

- (void)friendRequestReceived:(NSNotification *)notification
{
    NSString* fromJid = [notification object];
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: fromJid, @"jid", @"2", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"get config JSON received: %@", responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"]) {
            [self.friendRequestDict setValue:responseObject forKey:fromJid];
            
#warning TODO - add flag mark new friend request
            [self appDelegate].tabController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%d", [self.friendRequestDict count]];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        DDLogVerbose(@"error received: %@", error);
    }];
    

}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
