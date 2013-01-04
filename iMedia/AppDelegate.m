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
#import "Pluggin.h"
#import <CocoaPlant/NSManagedObject+CocoaPlant.h>
#import "AFNetworkActivityIndicatorManager.h"
#import "XMPPNetworkCenter.h"
#import "NearbyViewController.h"
#import "ConversationsController.h"
#import "ContactListViewController.h"
#import "FunctionListViewController.h"
#import "SettingViewController.h"
#import "LoginViewController.h"
#import "ConfigSetting.h"

#import "AppNetworkAPIClient.h"
#import "LocationManager.h"
#import "ModelHelper.h"
#import "NSObject+SBJson.h"
#import "XMPPJID.h"
#import <QuartzCore/QuartzCore.h>
#import <Foundation/NSTimer.h>
#import "ConfigSetting.h"
#import "PrivacyLoginViewController.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

#define NAVIGATION_CONTROLLER() ((UINavigationController *)_window.rootViewController)

@interface AppDelegate()<UIAlertViewDelegate>
{
    NSManagedObjectContext *_managedObjectContext;
    Conversation  *_conversation; // this is a mock
    NSMutableDictionary     *_messagesSending;
    SystemSoundID           _messageReceivedSystemSoundID;
    SystemSoundID           _messageSentSystemSoundID;
    NSUInteger              _updateChannelRetryCount;
    NSUInteger              _loginRetryCount;
}

@property (nonatomic, strong) NSTimer* updateChannelTimer;
@property (nonatomic, strong) NSTimer* loginTimer;
@property (nonatomic, strong) PrivacyLoginViewController *privacyLoginViewController;
@property (nonatomic, strong) UIViewController *transController;
@property (nonatomic, strong) UIAlertView *versionAlertView;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabController = _tabController;
@synthesize nearbyViewController;
@synthesize conversationController;
@synthesize contactListController;
@synthesize functionListController;
@synthesize settingController;
@synthesize updateChannelTimer;
@synthesize loginTimer;
@synthesize privacyLoginViewController;
@synthesize transController;
@synthesize versionAlertView;

@synthesize me = _me;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    // start log session
    [XFox startSession:@"cst0.1_201212"];
    [XFox setAppVersion:@"cst0.1"];
    
    application.statusBarHidden = NO;
    // Set up Core Data stack.
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"jiemo" withExtension:@"momd"]]];
    NSError *error;
    NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"jiemo.sqlite"] options:nil error:&error];
    if (store == nil) {
        DDLogVerbose(@"Add-Persistent-Store Error: %@", error);
    }
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
        if (!StringHasValue(self.me.displayName) || !StringHasValue(self.me.gender)) {
            [self startIntroSession];
        } else {
            [self connect];
            [self startMainSession];
        }
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
    
    //retry logic here
    //
    _updateChannelRetryCount = 0 ;
    _loginRetryCount = 0;
    self.updateChannelTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:10] interval:60 target:self selector:@selector(updateMyChannelInformation:) userInfo:nil repeats:YES];
  //  self.loginTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:2000] interval:5 target:self selector:@selector(reLogin:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.updateChannelTimer forMode:NSDefaultRunLoopMode];
  //  [[NSRunLoop currentRunLoop] addTimer:self.loginTimer forMode:NSDefaultRunLoopMode];
    
    // monitor for network status change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChangeReceived:)
                                                 name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
   // NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    self.privacyLoginViewController = [[PrivacyLoginViewController alloc]initWithNibName:nil bundle:nil];
    self.transController = [[UIViewController alloc]init];

    return YES;
}



//////////////////////////////////
#pragma mark - didRegisterForRemoteNotificationsWithDeviceToken
//////////////////////////////////
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenStr = [NSString stringWithFormat:@"%@",deviceToken];
    NSString *deviceTokenString = [[deviceTokenStr substringWithRange:NSMakeRange(0, 72)] substringWithRange:NSMakeRange(1, 71)];
    [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:@"deviceToken"];
    [[AppNetworkAPIClient sharedClient] postDeviceToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    
    NSString *str = [NSString stringWithFormat: @"Error: %@", err];
    DDLogVerbose(@"token %@",str);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    for (id key in userInfo) {
        DDLogVerbose(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
    }
    
}


- (void)startIntroSession
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    LoginViewController *loginViewController = [[LoginViewController alloc]initWithNibName:nil bundle:nil];
    UINavigationController *tt  = [[UINavigationController alloc]initWithRootViewController:loginViewController];
    
    [XFox logAllPageViews:tt];

    [self.window setRootViewController:tt];
    [self.window makeKeyAndVisible];
}

- (void)startMainSession
{
    // badge back to zero 
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;

    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert |
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound)];
    
    // Update local data with latest server info
    [self updateMeWithBlock:nil];    
    //
    // Creating all the initial controllers
    //
    self.tabController = [[UITabBarController alloc] init];
    
    
    self.nearbyViewController = [[NearbyViewController alloc]init];
    UINavigationController *navController1 = [[UINavigationController alloc] initWithRootViewController:self.nearbyViewController];
    self.nearbyViewController.title = T(@"附近");
    self.nearbyViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"附近") image:[UIImage imageNamed:@"tabbar_item_1.png"] tag:1001];
    
    self.conversationController = [[ConversationsController alloc] init];
    UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:self.conversationController];
    self.conversationController.managedObjectContext = _managedObjectContext;
    self.conversationController.title = T(@"消息");
    self.conversationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"消息") image:[UIImage imageNamed:@"tabbar_item_2.png"] tag:1002];
    
    self.contactListController = [[ContactListViewController alloc] initWithStyle:UITableViewStylePlain andManagementContext:_managedObjectContext];
    UINavigationController *navController3 = [[UINavigationController alloc] initWithRootViewController:self.contactListController];
    self.contactListController.title = T(@"联系人");
    self.contactListController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"联系人")  image:[UIImage imageNamed:@"tabbar_item_3.png"] tag:1003];
    
    self.functionListController = [[FunctionListViewController alloc] init];
    UINavigationController *navController4 = [[UINavigationController alloc] initWithRootViewController:self.functionListController];
    self.functionListController.managedObjectContext = _managedObjectContext;
    self.functionListController.title = T(@"百宝箱");
    self.functionListController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"百宝箱") image:[UIImage imageNamed:@"tabbar_item_4.png"] tag:1004];
    
    self.settingController = [[SettingViewController alloc] init];
    self.settingController.managedObjectContext = _managedObjectContext;
    UINavigationController *navController5 = [[UINavigationController alloc] initWithRootViewController:self.settingController];
    self.settingController.title = T(@"设置");
    self.settingController.tabBarItem = [[UITabBarItem alloc] initWithTitle:T(@"设置") image:[UIImage imageNamed:@"tabbar_item_5.png"] tag:1005];
    
    NSArray* controllers = [NSArray arrayWithObjects:navController1, navController2, navController3, navController4, navController5, nil];
    self.tabController.viewControllers = controllers;

    [XFox logAllPageViews:navController1];
    [XFox logAllPageViews:navController2];
    [XFox logAllPageViews:navController3];
    [XFox logAllPageViews:navController4];
    [XFox logAllPageViews:navController5];
    
    // tabtar style
    [self.tabController.tabBar setFrame:CGRectMake(0, 430.0, 320.0, 50.0)];
    UIImageView *tabbarBgView  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tabbar_bg.png"]];
    [self.tabController.tabBar insertSubview:tabbarBgView atIndex:1];
    [self.tabController.tabBar setTintColor:[UIColor grayColor]];
    [self.tabController.tabBar setSelectedImageTintColor:RGBCOLOR(151, 206, 45)];
    [self.tabController.tabBar setSelectionIndicatorImage:[UIImage imageNamed:@"tabbar_overlay.png"]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window addSubview:self.tabController.view];
    [self.window setRootViewController:self.tabController];

    [self checkIOSVersion];
    [self.window makeKeyAndVisible];
}

// check version
- (void)checkIOSVersion
{
    NSString *iOSVersion =  [[NSUserDefaults standardUserDefaults] objectForKey:@"ios_ver"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    self.versionAlertView = [[UIAlertView alloc]initWithTitle:T(@"目前有新版本，是否升级") message:T(@"更多新功能，运行更流畅") delegate:self cancelButtonTitle:T(@"否") otherButtonTitles:T(@"是"), nil];
    
    if (StringHasValue(iOSVersion) && ![iOSVersion isEqualToString:version]) {
        [self.versionAlertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView isEqual:self.versionAlertView]) {
        if (buttonIndex == 0){
            //cancel clicked ...do your action
        }else if (buttonIndex == 1){
            NSString *str = [NSString stringWithFormat:
                             @"itms-apps://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%d",
                             M_APPLEID ];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];

        }
    }
}

/*
- (void)reLogin:(NSNotification *)notification
{
    [[AppNetworkAPIClient sharedClient] loginWithRetryCount:1 username:self.me.username andPassword:self.me.password withBlock:^(id responseObject, NSError *error) {
        //
        // login only succeeded with non-nil responseObject and nil error
        if (responseObject != nil && error == nil) {
            [self.loginTimer invalidate];
        } else if (responseObject != nil && error != nil) {
            // we did receive server response, but the login failed for other reason
            // this should never happen since we already logged in the past
            // unless the password is changed for some other reason
#warning TODO - handle password changes
            [self.loginTimer invalidate];
        } else {
            // well, we need keep our timer going
            _loginRetryCount += 1;
            NSTimeInterval seconds = 0;
            if (_updateChannelRetryCount > 3) {
                seconds = 60;
            } else {
                seconds = _updateChannelRetryCount * 2;
            }
            [self.updateChannelTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
        }
    }];
}
 */

- (void)updateMyChannelInformation:(NSNotification *)notification
{
    if ([[XMPPNetworkCenter sharedClient] isConnected] != YES) {
        // wait for the XMPPServer connection, otherwise do nothing
        return;
    }
    
    [[AppNetworkAPIClient sharedClient] updateMyChannel:self.me withBlock:^(id responseObject, NSError *error) {
        if (responseObject != nil) {
            // When Sync local channel information from Server, there are a couple scenarios
            // for what exists on the server, local could be 1) in sync; 2) doesn't exist; 3) exist out of sync;
            // for what exists locally, server could be 1) in sync; 2) doesn't exist; 3) out of sync
            // server only returns currently subscribed channel so the scenario simplified to be:
            // 1) all server returns should be in local db with subscribed state;
            // 2) except for these server returns, all other local channels need to be either Inactive, or if they
            // are in pending (add/removal) state, these requests need to be redrived.
            
            
            NSMutableDictionary *allServerChannels = [NSMutableDictionary dictionaryWithCapacity:5];
            NSMutableSet *channelsToSubscribe = [NSMutableSet setWithCapacity:5];
            NSMutableSet *channelsToUnsubscribe = [NSMutableSet setWithCapacity:5];
            
            NSArray *allServerChannelsArray = [responseObject allValues];
            [allServerChannelsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *channelInfo = obj;
                
                // Sync channels from Servers
                NSString *nodeStr = [channelInfo objectForKey:@"node_address"];
                Channel *aChannel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
                
                if (aChannel == nil) {
                    aChannel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:_managedObjectContext];
                    aChannel.owner = self.me;
                    [[ModelHelper sharedInstance] populateIdentity:aChannel withJSONData:channelInfo];
                    aChannel.state = IdentityStateActive;
                    
                } else if (aChannel.state == IdentityStateActive){
                    // already exists and good, just refresh content, no special handing here
                    [[ModelHelper sharedInstance] populateIdentity:aChannel withJSONData:channelInfo];
                    
                } else if (aChannel.state == IdentityStatePendingAddSubscription || aChannel.state == IdentityStateInactive) {
                    // this should not happen, but we can sub again to clear the state;
                    [channelsToSubscribe addObject:aChannel];
                } else if (aChannel.state == IdentityStatePendingRemoveSubscription) {
                    [channelsToUnsubscribe addObject:aChannel];
                }
                
                [allServerChannels setObject:aChannel forKey:nodeStr];
            }];
            
            
            // Now i will go through all local channels to check their status
            [self.me.channels enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                Channel* aChannel = obj;
                if (aChannel.state == IdentityStateActive) {
                    if ([allServerChannels objectForKey:aChannel.node] == nil) {
                        [channelsToUnsubscribe addObject:aChannel];
                    }
                } else if (aChannel.state == IdentityStatePendingAddSubscription) {
                    [channelsToSubscribe addObject:aChannel];
                } else if (aChannel.state == IdentityStatePendingRemoveSubscription) {
                    [channelsToUnsubscribe addObject:aChannel];
                }
            }];
            
            // Now process all the channel stuff
            [channelsToSubscribe enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                Channel *aChannel = obj;
                aChannel.subrequestID = [[XMPPNetworkCenter sharedClient] subscribeToChannel:aChannel.node withCallbackBlock:nil];
            }];
            [channelsToUnsubscribe enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                Channel *aChannel = obj;
                aChannel.subrequestID = [[XMPPNetworkCenter sharedClient] unsubscribeToChannel:aChannel.node withCallbackBlock:nil];
            }];
            
            [[AppNetworkAPIClient sharedClient] updateMyPresetChannel:self.me withBlock:^(id responseObject, NSError *error) {
                if (responseObject != nil) {
                    // When Sync local channel information from Server, there are a couple scenarios
                    // for what exists on the server, local could be 1) in sync; 2) doesn't exist; 3) exist out of sync;
                    // for what exists locally, server could be 1) in sync; 2) doesn't exist; 3) out of sync
                    // server only returns currently subscribed channel so the scenario simplified to be:
                    // 1) all server returns should be in local db with subscribed state;
                    // 2) except for these server returns, all other local channels need to be either Inactive, or if they
                    // are in pending (add/removal) state, these requests need to be redrived.
                    
                    
                    NSMutableDictionary *allServerChannels = [NSMutableDictionary dictionaryWithCapacity:5];
                    NSMutableSet *channelsToSubscribe = [NSMutableSet setWithCapacity:5];
                    NSMutableSet *channelsToUnsubscribe = [NSMutableSet setWithCapacity:5];
                    
                    NSArray *allServerChannelsArray = [responseObject allValues];
                    [allServerChannelsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSDictionary *channelInfo = obj;
                        
                        // Sync channels from Servers
                        NSString *nodeStr = [channelInfo objectForKey:@"node_address"];
                        Channel *aChannel = [[ModelHelper sharedInstance] findChannelWithNode:nodeStr];
                        
                        if (aChannel == nil) {
                            aChannel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:_managedObjectContext];
                            aChannel.owner = self.me;
                            [[ModelHelper sharedInstance] populateIdentity:aChannel withJSONData:channelInfo];
                            aChannel.state = IdentityStatePendingAddSubscription;
                            [channelsToSubscribe addObject:aChannel];
                            
                        } else if (aChannel.state == IdentityStateActive){
                            // already exists and good, just refresh content, no special handing here
                            [[ModelHelper sharedInstance] populateIdentity:aChannel withJSONData:channelInfo];
                            
                        } else if (aChannel.state == IdentityStatePendingAddSubscription || aChannel.state == IdentityStateInactive) {
                            // this should not happen, but we can sub again to clear the state;
                            [channelsToSubscribe addObject:aChannel];
                        } else if (aChannel.state == IdentityStatePendingRemoveSubscription) {
                            [channelsToUnsubscribe addObject:aChannel];
                        }
                        
                        aChannel.isMandatory = [NSNumber numberWithBool:YES];
                        
                        [allServerChannels setObject:aChannel forKey:nodeStr];
                    }];
                    
                    
                    // Now process all the channel stuff
                    [channelsToSubscribe enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                        Channel *aChannel = obj;
                        aChannel.subrequestID = [[XMPPNetworkCenter sharedClient] subscribeToChannel:aChannel.node withCallbackBlock:nil];
                    }];
                    [channelsToUnsubscribe enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                        Channel *aChannel = obj;
                        aChannel.subrequestID = [[XMPPNetworkCenter sharedClient] unsubscribeToChannel:aChannel.node withCallbackBlock:nil];
                    }];
                    
                    [self.contactListController contentChanged];
                    
                    [self.updateChannelTimer invalidate];
                } else {
                    _updateChannelRetryCount += 1;
                    NSTimeInterval seconds = 0;
                    if (_updateChannelRetryCount > 3) {
                        seconds = 60;
                    } else {
                        seconds = _updateChannelRetryCount * 2;
                    }
                    [self.updateChannelTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
                }
            }];
            
            [self.contactListController contentChanged];
            
            
        } else {
            _updateChannelRetryCount += 1;
            NSTimeInterval seconds = 0;
            if (_updateChannelRetryCount > 3) {
                seconds = 60;
            } else {
                seconds = _updateChannelRetryCount * 2;
            }
            [self.updateChannelTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
        }
    }];
}

- (void)updateMeWithBlock:(void (^)(id responseObject, NSError *error))block
{
    [LocationManager sharedInstance].me = self.me;
    
    if (self.friendRequestPluggin == nil) {
        self.friendRequestPluggin = [[ModelHelper sharedInstance] findFriendRequestPluggin];
    }
    
    [self updateMyChannelInformation:nil];
    
    [[AppNetworkAPIClient sharedClient] updateIdentity:self.me withBlock:block];
}

-(void)createMeAndOtherOneTimeObjectsWithUsername:(NSString *)username password:(NSString *)passwd jid:(NSString *)jidStr jidPasswd:(NSString *)jidPass andGUID:(NSString *)guid withBlock:(void (^)(id responseObject, NSError *error))block
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
        XMPPJID *bareJid = [XMPPJID jidWithString:jidStr];
        self.me.ePostalID = [bareJid bare];
        self.me.fullEPostalID = jidStr;
        self.me.ePostalPassword = jidPass;
        self.me.type = IdentityTypeMe;
        self.me.displayName = jidStr;
        self.me.username = username;
        self.me.password = passwd;
        self.me.guid = guid;
        self.me.state = IdentityStatePendingServerDataUpdate;
        self.me.birthdate = nil;
        self.me.selfIntroduction = @"";
        self.me.signature = @"";
        self.me.career = @"";
        self.me.config = [ConfigSetting getDefaultConfig];
        self.me.lastSearchPreference = @"";
        self.me.sinaWeiboID = @"";

        self.friendRequestPluggin = [NSEntityDescription insertNewObjectForEntityForName:@"Pluggin" inManagedObjectContext:_managedObjectContext];
        self.friendRequestPluggin.displayName = T(@"好友请求消息");
        self.friendRequestPluggin.state = IdentityStatePlugginIsEnabled;
        self.friendRequestPluggin.type = IdentityTypePlugginFriendRequest;
        self.friendRequestPluggin.thumbnailImage = [UIImage imageNamed:@"plugin_request.png"];
        self.friendRequestPluggin.plugginID = IdentityTypePlugginFriendRequest;
        
        MOCSave(_managedObjectContext);
    }    
    [self updateMeWithBlock:block];
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
    if (![[XMPPNetworkCenter sharedClient] connectWithUsername:self.me.fullEPostalID andPassword:self.me.ePostalPassword])
    {
        DDLogVerbose(@"%@: %@ cannot connect to XMPP server", THIS_FILE, THIS_METHOD);
        return NO;
    }
    [[AppNetworkAPIClient sharedClient] loginWithRetryCount:3 username:self.me.username andPassword:self.me.password withBlock:nil];
    
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
    //[[XMPPNetworkCenter sharedClient] disconnect];
    [self saveContext];
    [UIApplication sharedApplication].applicationIconBadgeNumber = self.conversationController.unreadMessageCount;
    [XFox logEvent:EVENT_ENTER_BACKGROUND];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    _messagesSending = [NSMutableDictionary dictionary];
    [self connect];
    [XFox logEvent:EVENT_ENTER_FOREGROUND];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if([ConfigSetting isSettingEnabled:self.me.config withSetting:CONFIG_PRIVACY_REQUIRED] && StringHasValue(self.me.privacyPass) ){
        if (![self.window.rootViewController isKindOfClass:[privacyLoginViewController class]]) {
            self.transController = self.window.rootViewController;
            self.window.rootViewController = self.privacyLoginViewController;
        }
        [self.privacyLoginViewController initInterface];
    }else{
        if ([self.window.rootViewController isKindOfClass:[privacyLoginViewController class]]) {
            self.window.rootViewController = self.transController;
        }

    }
}

- (void)transformPrivacyLogin
{
    self.window.rootViewController = self.transController;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [[XMPPNetworkCenter sharedClient] disconnect];
    [self saveContext];
}

- (void)saveContextInDefaultLoop
{
    [self performSelectorOnMainThread:@selector(saveContext) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}
- (void)saveContext
{
    NSError *error = nil;
    if (_managedObjectContext != nil) {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            DDLogVerbose(@"Unresolved error saving object context s%@, %@", error, [error userInfo]);
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

- (void)clearSession
{
    [[XMPPNetworkCenter sharedClient] disconnect];
    self.contactListController = nil;
    self.conversationController = nil;
    self.nearbyViewController = nil;
    self.settingController = nil;
    self.functionListController = nil;
    self.me = nil;
    self.friendRequestPluggin = nil;
    [AppNetworkAPIClient sharedClient].isLoggedIn = NO;
}

- (void)networkChangeReceived:(NSNotification *)notification
{
    NSNumber *status = (NSNumber *)[notification.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem];
    if ((status.intValue == AFNetworkReachabilityStatusReachableViaWiFi || status.intValue == AFNetworkReachabilityStatusReachableViaWWAN) && (self.me != nil)) {
        [self connect];
    } else {

    }
}

@end
