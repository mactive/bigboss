//
//  AppDelegate.m
//  iMedia
//
//  Created by Li Xiaosi on 9/19/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "Message.h"
#import "User.h"
#import "ImageRemote.h"
#import "Me.h"
#import "Avatar.h"
#import "Channel.h"
#import "Conversation.h"
#import "AppDefs.h"
#import <CocoaPlant/NSManagedObject+CocoaPlant.h>
#import "AFNetworkActivityIndicatorManager.h"
#import "XMPPNetworkCenter.h"

#import "ConversationsController.h"
#import "ContactListViewController.h"
#import "FunctionListViewController.h"
#import "SettingViewController.h"
#import "LoginViewController.h"

#import "AppNetworkAPIClient.h"
#import "LocationManager.h"
#import "ModelHelper.h"
#import "NSObject+SBJson.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define NAVIGATION_CONTROLLER() ((UINavigationController *)_window.rootViewController)

#define CHANNEL_UPDATE_REQUEST_EVENT   @"Channel_Update_Request_Event"

@interface AppDelegate()
{
    NSManagedObjectContext *_managedObjectContext;
    Conversation  *_conversation; // this is a mock
    NSMutableDictionary     *_messagesSending;
    SystemSoundID           _messageReceivedSystemSoundID;
    SystemSoundID           _messageSentSystemSoundID;
}
-(void)startIntroSession;

@end


@implementation AppDelegate

@synthesize window = _window;
@synthesize tabController = _tabController;
@synthesize conversationController;
@synthesize contactListController;
@synthesize functionListController;
@synthesize settingController;

@synthesize me = _me;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"iMedia" withExtension:@"momd"]]];
    NSError *error;
    NSAssert([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"iMedia.sqlite"] options:nil error:&error], @"Add-Persistent-Store Error: %@", error);
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    [ModelHelper sharedInstance].managedObjectContext = _managedObjectContext;
    
    // Setup the network
    [[XMPPNetworkCenter sharedClient] setupWithHostname:nil andPort:0];
    [XMPPNetworkCenter sharedClient].managedObjectContext = _managedObjectContext;
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];

    //Start Location Service and needs to prompt user to turn it on if not
    if ([LocationManager sharedInstance].isAllowed == NO) {
        // do sth here
    }
    
    // check whether first use
    NSArray *fetchedUsers = MOCFetchAll(_managedObjectContext, @"Me");
    if ([fetchedUsers count] == 0) {
        [self startIntroSession];
    } else if ([fetchedUsers count] == 1) {
        self.me = [fetchedUsers objectAtIndex:0];
        [self connect];
        [self startMainSession];
    } else {
        DDLogVerbose(@"%@: %@ multiple ME instance", THIS_FILE, THIS_METHOD);
    }

        
    // Global UINavigationBar style 
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBar_bg.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:121/255 green:123/255 blue:126/255 alpha:1.0] ];    
    [[UIBarButtonItem appearance] setTintColor:RGBACOLOR(55, 61, 70, 1)];
    
    self.window.backgroundColor = BGCOLOR;
    
    application.applicationSupportsShakeToEdit = YES;
    
    // Add notification to enable keeping trying update channel data
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateMyChannelInformation:)
                                                 name:CHANNEL_UPDATE_REQUEST_EVENT object:nil];
    return YES;
}

- (void)startIntroSession
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    LoginViewController *loginViewController = [[LoginViewController alloc]initWithNibName:nil bundle:nil];
    UINavigationController *tt  = [[UINavigationController alloc]initWithRootViewController:loginViewController];
    

    [self.window setRootViewController:tt];
    [self.window makeKeyAndVisible];
}

- (void)startMainSession
{
    [LocationManager sharedInstance].me = self.me;
    // Update local data with latest server info
    [[AppNetworkAPIClient sharedClient] updateIdentity:(Identity *)self.me withBlock:nil];
    
    //
    // Creating all the initial controllers
    //
    self.tabController = [[UITabBarController alloc] init];
    
    self.conversationController = [[ConversationsController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.conversationController];
    self.conversationController.managedObjectContext = _managedObjectContext;
    self.conversationController.title = T(@"消息");
    self.conversationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"消息") image:[UIImage imageNamed:@"tabbar_item_0.png"] tag:1000];
    
    self.contactListController = [[ContactListViewController alloc] initWithStyle:UITableViewStylePlain andManagementContext:_managedObjectContext];
    UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:self.contactListController];
//    self.contactListController.managedObjectContext = _managedObjectContext;
    self.contactListController.title = T(@"联系人");
    self.contactListController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"联系人")  image:[UIImage imageNamed:@"tabbar_item_1.png"] tag:1001];
    
    self.functionListController = [[FunctionListViewController alloc] init];
    UINavigationController *navController3 = [[UINavigationController alloc] initWithRootViewController:self.functionListController];
    self.functionListController.managedObjectContext = _managedObjectContext;
    self.functionListController.title = T(@"朋友们");
    self.functionListController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"朋友们") image:[UIImage imageNamed:@"tabbar_item_2.png"] tag:1002];
    
    NSLog(@"---- %@",NSStringFromCGRect(navController3.view.frame));

    self.settingController = [[SettingViewController alloc] init];
    self.settingController.managedObjectContext = _managedObjectContext;
    UINavigationController *navController4 = [[UINavigationController alloc] initWithRootViewController:self.settingController];
    self.settingController.title = T(@"设置");
    self.settingController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"设置") image:[UIImage imageNamed:@"tabbar_item_3.png"] tag:1003];
    
    NSArray* controllers = [NSArray arrayWithObjects:navController, navController2, navController3, navController4, nil];
    self.tabController.viewControllers = controllers;

    // tabtar style
    [self.tabController.tabBar setFrame:CGRectMake(0, 430.0, 320.0, 50.0)];
    UIImageView *tabbarBgView  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tabbar_bg.png"]];
    [self.tabController.tabBar insertSubview:tabbarBgView atIndex:1];
    [self.tabController.tabBar setTintColor:[UIColor grayColor]];
    [self.tabController.tabBar setSelectedImageTintColor:[UIColor whiteColor]];
    [self.tabController.tabBar setSelectionIndicatorImage:[UIImage imageNamed:@"tabbar_overlay.png"]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window addSubview:self.tabController.view];
    [self.window setRootViewController:self.tabController];

    [self.window makeKeyAndVisible];
}

- (void)updateMyChannelInformation:(NSNotification *)notification
{
    [[AppNetworkAPIClient sharedClient] updateMyChannel:self.me withBlock:^(id responseObject, NSError *error) {
        if (responseObject != nil) {
            NSArray *allChannelsArray = [responseObject allValues];
            for (int i = 0; i < [allChannelsArray count]; i++) {
                NSDictionary *channelInfo = [allChannelsArray objectAtIndex:i];
                
                // create Channel subscription
                NSString *nodeStr = [channelInfo objectForKey:@"node_address"];
                Channel *newChannel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
                if (newChannel == nil) {
                    newChannel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:_managedObjectContext];
                }
                [[ModelHelper sharedInstance] populateIdentity:newChannel withJSONData:channelInfo];
                newChannel.state = [NSNumber numberWithInt:IdentityStateActive];
            }
            
            [self.contactListController contentChanged];
        } else {
            NSNotification *myNotification =
            [NSNotification notificationWithName:CHANNEL_UPDATE_REQUEST_EVENT object:nil];
            [[NSNotificationQueue defaultQueue]
             enqueueNotification:myNotification
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationNoCoalescing
             forModes:nil];
        }
    }];
}

-(void)createMeWithUsername:(NSString *)username password:(NSString *)passwd jid:(NSString *)jidStr jidPasswd:(NSString *)jidPass andGUID:(NSString *)guid withBlock:(void (^)(id responseObject, NSError *error))block
{
    if(self.me == nil) {
        self.me = [NSEntityDescription insertNewObjectForEntityForName:@"Me" inManagedObjectContext:_managedObjectContext];
        for (int i = 0; i < 8; i++) {
            Avatar *image = [NSEntityDescription insertNewObjectForEntityForName:@"ImageLocal" inManagedObjectContext:_managedObjectContext];
            image.sequence = [NSNumber numberWithInt:(i+1)];
            image.image = nil;
            image.thumbnail = nil;
            image.title = @"";
            [self.me addAvatarsObject:image];
        }
        self.me.ePostalID = jidStr;
        self.me.ePostalPassword = jidPass;
        self.me.type = [NSNumber numberWithInt:IdentityTypeMe];
        self.me.displayName = jidStr;
        self.me.username = username;
        self.me.password = passwd;
        self.me.guid = guid;
        self.me.state = [NSNumber numberWithInt:IdentityStatePendingServerDataUpdate];
        self.me.birthdate = [NSDate dateWithTimeIntervalSince1970:0];
        self.me.selfIntroduction = @"";
        self.me.signature = @"";
        self.me.career = @"";
        
        [LocationManager sharedInstance].me = self.me;
        
        [self updateMyChannelInformation:nil];
        
        [[AppNetworkAPIClient sharedClient] updateIdentity:self.me withBlock:block];
        
        MOCSave(_managedObjectContext);
    }

}

- (NSManagedObjectContext *)context
{
    return _managedObjectContext;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
    if (![[XMPPNetworkCenter sharedClient] connectWithUsername:self.me.ePostalID andPassword:self.me.ePostalPassword])
    {
        DDLogVerbose(@"%@: %@ cannot connect to XMPP server", THIS_FILE, THIS_METHOD);
        return NO;
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[XMPPNetworkCenter sharedClient] disconnect];
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    _messagesSending = [NSMutableDictionary dictionary];
    [[AppNetworkAPIClient sharedClient]loginWithUsername:self.me.username andPassword:self.me.password withBlock:nil];
    [self connect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    if (_managedObjectContext != nil) {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error saving object context s%@, %@", error, [error userInfo]);
        } 
    }
}

////////////////////////////////////////////////////////////////////////////////////
#pragma mark - disableLeftBarButtonItemOnNavbar
////////////////////////////////////////////////////////////////////////////////////
- (void) disableLeftBarButtonItemOnNavbar:(BOOL)disable
{
    static UIImageView *l = nil;
    
    if (disable) {
        if (l != nil)
            return;
        l = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 80, 44)];
        l.image = [UIImage imageNamed:@"navigationBar_bg_part.png"];
        l.userInteractionEnabled = YES;
        [self.window addSubview:l];
    }
    else {
        if (l == nil)
            return;
        [l removeFromSuperview];
        l = nil;
    }
}


@end
