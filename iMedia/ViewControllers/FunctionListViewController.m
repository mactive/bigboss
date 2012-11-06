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
#import "FriendRequest.h"
#import "ModelHelper.h"
#import "MetroButton.h"

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
@synthesize friendRequestDict;
@synthesize managedObjectContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.friendRequestDict = [NSMutableDictionary dictionaryWithCapacity:5];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(friendRequestReceived:)
                                                     name:NEW_FRIEND_NOTIFICATION object:nil];
        self.newFriendRequestCount  = 0;
    }
    return self;
}

#define VIEW_ALBUM_OFFSET 10
#define VIEW_ALBUM_WIDTH 145
#define COUNT_PER_LINE 2

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % COUNT_PER_LINE * 1 + 1) + VIEW_ALBUM_WIDTH * (index % COUNT_PER_LINE) ;
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / COUNT_PER_LINE) * 1 + 1) + VIEW_ALBUM_WIDTH * floor(index / COUNT_PER_LINE);
    return  CGRectMake( x, y, VIEW_ALBUM_WIDTH, VIEW_ALBUM_WIDTH);
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:@"附近的人", @"打招呼的人", @"摇一摇",@"百宝箱", nil];
    
    [self.view addSubview:self.settingView];
    
    for (int index = 0; index <[self.settingTitleArray count]; index++) {
        MetroButton *button = [[MetroButton alloc]initWithFrame:[self calcRect:index]];
        NSString *title = [self.settingTitleArray objectAtIndex:index];
        NSString *image = [NSString stringWithFormat:@"metro_icon_%d.png",(index+1)];
        [button initMetroButton:[UIImage imageNamed:image] andText:title andIndex:index];
        
        if (index == 1) {
            [button addTarget:self action:@selector(sayhiAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 2) {
            [button addTarget:self action:@selector(shakeAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
    }

    
    
#warning TODO: paged fetch - don't fetch all at the same time
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"FriendRequest" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    
    for (int i = 0; i < [array count]; i++) {
        FriendRequest *request = [array objectAtIndex:i];
        [self.friendRequestDict setValue:request forKey:request.requesterEPostalID];
    }
}

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actions
////////////////////////////////////////////////////////////////////////////////////////
- (void)sayhiAction
{
    if ([self.friendRequestDict count] == 1) {
        RequestViewController *controller = [[RequestViewController alloc] initWithNibName:nil bundle:nil];
        controller.request = [[self.friendRequestDict allValues] objectAtIndex:0];
        [self.navigationController pushViewController:controller animated:YES];
        
        //            FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
        //            controller.friendRequestArray = [NSMutableArray arrayWithArray:[self.friendRequestDict allValues]];
        //            [self.navigationController pushViewController:controller animated:YES];
        
    } else if ([self.friendRequestDict count] > 1) {
        FriendRequestListViewController *controller = [[FriendRequestListViewController alloc] initWithNibName:nil bundle:nil];
        controller.friendRequestArray = [NSMutableArray arrayWithArray:[self.friendRequestDict allValues]];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)shakeAction
{
    ShakeViewController *shakeViewController = [[ShakeViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:shakeViewController animated:YES];
}





- (void)friendRequestReceived:(NSNotification *)notification
{
    NSString* fromJid = [notification object];
    
    NSDictionary *getDict = [NSDictionary dictionaryWithObjectsAndKeys: fromJid, @"jid", @"2", @"op", nil];
    
    [[AppNetworkAPIClient sharedClient] getPath:GET_DATA_PATH parameters:getDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"friend request - get user %@ data received: %@", fromJid, responseObject);
        
        NSString* type = [responseObject valueForKey:@"type"];
        if ([type isEqualToString:@"user"] && [self.friendRequestDict valueForKey:fromJid] == nil) {
            
            FriendRequest *newFriendRequest = [[ModelHelper sharedInstance] newFriendRequestWithEPostalID:fromJid andJson:responseObject];

            [self.friendRequestDict setValue:newFriendRequest forKey:fromJid];
            self.newFriendRequestCount += 1;
            
            
#warning TODO - add flag mark new friend request
            [self appDelegate].functionListController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%@", self.newFriendRequestCount];
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
