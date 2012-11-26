//
//  FunctionListViewController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/29/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FunctionListViewController.h"
#import "ShakeDashboardViewController.h"
#import "XMPPNetworkCenter.h"
#import "AppNetworkAPIClient.h"
#import "AppDelegate.h" 
#import "RequestViewController.h"
#import "FriendRequestListViewController.h"
#import "FriendRequest.h"
#import "ModelHelper.h"
#import "MetroButton.h"
#import "ChannelListViewController.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface FunctionListViewController ()

@property(nonatomic, strong) UIView *settingView;
@property(nonatomic, strong) NSArray *settingTitleArray;
@property(nonatomic, strong) NSArray *settingDescArray;

@end

@implementation FunctionListViewController

@synthesize settingView;
@synthesize settingDescArray;
@synthesize settingTitleArray;
@synthesize friendRequestArray;
@synthesize managedObjectContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(friendRequestReceived:)
                                                     name:NEW_FRIEND_NOTIFICATION object:nil];
        self.newFriendRequestCount  = 0;
    }
    return self;
}

#define VIEW_ALBUM_OFFSET 10
#define VIEW_ALBUM_WIDTH 300
#define VIEW_ALBUM_HEIGHT 100
#define COUNT_PER_LINE 1
#define Y_OFFEST 14

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % COUNT_PER_LINE * 1 + 1) + VIEW_ALBUM_WIDTH * (index % COUNT_PER_LINE) ;
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / COUNT_PER_LINE) * 1 + 1) + VIEW_ALBUM_HEIGHT * floor(index / COUNT_PER_LINE);
    return  CGRectMake( x, y+Y_OFFEST, VIEW_ALBUM_WIDTH, VIEW_ALBUM_HEIGHT);
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:@"打招呼的人", @"摇一摇",@"频道列表", nil];
    
    [self.view addSubview:self.settingView];
    
    for (int index = 0; index <[self.settingTitleArray count]; index++) {
        MetroButton *button = [[MetroButton alloc]initWithFrame:[self calcRect:index]];
        NSString *title = [self.settingTitleArray objectAtIndex:index];
        NSString *image = [NSString stringWithFormat:@"metro_icon_%d.png",(index+2)];
        [button initMetroButton:[UIImage imageNamed:image] andText:title andIndex:index];
        
        if (index == 0) {
            [button addTarget:self action:@selector(sayhiAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 1) {
            [button addTarget:self action:@selector(shakeAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 2) {
            [button addTarget:self action:@selector(channelListAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self initFriendRequestDictFromDB];

}
- (void) initFriendRequestDictFromDB
{
    // Need to sort the returned value, because 
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"FriendRequest" inManagedObjectContext:moc];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"requestDate" ascending:YES];
    NSArray *sortDescArray = [NSArray arrayWithObject:sortDesc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setSortDescriptors:sortDescArray];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    self.friendRequestArray = [NSMutableArray arrayWithArray:array];
}

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actions
////////////////////////////////////////////////////////////////////////////////////////
- (void)sayhiAction
{
    if ([self.friendRequestArray count] == 1) {
        RequestViewController *controller = [[RequestViewController alloc] initWithNibName:nil bundle:nil];
        controller.request = [self.friendRequestArray objectAtIndex:0];
        [self.navigationController pushViewController:controller animated:YES];
        
        //            FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
        //            controller.friendRequestArray = [NSMutableArray arrayWithArray:[self.friendRequestDict allValues]];
        //            [self.navigationController pushViewController:controller animated:YES];
        
    } else if ([self.friendRequestArray count] > 1) {
        FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
        controller.friendRequestArray = self.friendRequestArray;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)shakeAction
{
    ShakeDashboardViewController *shakeDashboardViewController = [[ShakeDashboardViewController alloc] initWithNibName:nil bundle:nil];
//    [self.navigationController setHidesBottomBarWhenPushed:YES];
    shakeDashboardViewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:shakeDashboardViewController animated:YES];
}

- (void)channelListAction
{
    ChannelListViewController *controller = [[ChannelListViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
}


- (void)friendRequestReceived:(NSNotification *)notification
{
    NSString* fromJid = [notification object];
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: fromJid, @"jid", @"2", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"friend request - get user %@ data received: %@", fromJid, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"]) {
            
            if ([self.friendRequestArray count] == 0) {
                [self initFriendRequestDictFromDB];
            }

            // filter off duplicates
            BOOL exists = false;
            for (int i = 0; i < [self.friendRequestArray count]; i++) {
                FriendRequest *request = [self.friendRequestArray objectAtIndex:i];
                if ([request.requesterEPostalID isEqualToString:fromJid] &&
                    (request.state == FriendRequestUnprocessed)) {
                    exists = YES;
                }
            }
            if (!exists) {
                FriendRequest *newFriendRequest = [[ModelHelper sharedInstance] newFriendRequestWithEPostalID:fromJid andJson:responseObject];
                MOCSave(self.managedObjectContext);
                [self.friendRequestArray addObject:newFriendRequest];
                self.newFriendRequestCount +=1;
            }
            
            if (self.newFriendRequestCount > 0 ) {
                [self appDelegate].functionListController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%i", self.newFriendRequestCount];
            } else {
                [self appDelegate].functionListController.tabBarItem.badgeValue =  nil;
            }
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
