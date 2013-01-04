//
//  SinaWeiboViewController.m
//  jiemo
//
//  Created by meng qian on 12-12-10.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import "SinaWeiboViewController.h"
#import "SinaWeibo.h"
#import "SinaWeiboRequest.h"
#import "MBProgressHUD.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface SinaWeiboViewController ()<SinaWeiboDelegate, SinaWeiboRequestDelegate>
{
    SinaWeibo *sinaweibo;
}

@property(nonatomic,strong) NSDictionary *userInfo;
@property(nonatomic,strong) NSArray *statuses;
@property(nonatomic,strong) NSString *postStatusText;
@property(nonatomic,strong) NSString *postImageStatusText;

@end

@implementation SinaWeiboViewController
@synthesize userInfo;
@synthesize statuses;
@synthesize postImageStatusText;
@synthesize postStatusText;
@synthesize valueIndex;
@synthesize passDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        sinaweibo = [[SinaWeibo alloc] initWithAppKey:kAppKey appSecret:kAppSecret appRedirectURI:kAppRedirectURI andDelegate:self];
        sinaweibo.delegate = self;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *sinaweiboInfo = [defaults objectForKey:@"SinaWeiboAuthData"];
        if ([sinaweiboInfo objectForKey:@"AccessTokenKey"] && [sinaweiboInfo objectForKey:@"ExpirationDateKey"] && [sinaweiboInfo objectForKey:@"UserIDKey"])
        {
            sinaweibo.accessToken = [sinaweiboInfo objectForKey:@"AccessTokenKey"];
            sinaweibo.expirationDate = [sinaweiboInfo objectForKey:@"ExpirationDateKey"];
            sinaweibo.userID = [sinaweiboInfo objectForKey:@"UserIDKey"];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"新浪微博绑定");
    if (sinaweibo.userID) {
        // 绑定过
    }else{
        [sinaweibo logIn];
    }
	// Do any additional setup after loading the view.
}

// 绑定成功后 会出现页面 在百宝箱后面
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    sinaweibo = nil;
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - sina delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sinaweiboDidLogIn:(SinaWeibo *)weibo
{
    DDLogVerbose(@"sinaweiboDidLogIn userID = %@ accesstoken = %@ expirationDate = %@ refresh_token = %@", weibo.userID, weibo.accessToken, weibo.expirationDate,weibo.refreshToken);
    
    [self.passDelegate passStringValue:weibo.userID andIndex:self.valueIndex];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = T(@"新浪微博绑定成功");
    
    [hud showAnimated:YES whileExecutingBlock:^{
        sleep(2);
    } completionBlock:^{
        [self.navigationController popViewControllerAnimated:YES];

    }];
    
//    [self resetButtons];
//    [self storeAuthData];
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - SinaWeiboRequest Delegate
/////////////////////////////////////////////////////////////////////////////////////

- (void)request:(SinaWeiboRequest *)request didFailWithError:(NSError *)error
{
    if ([request.url hasSuffix:@"users/show.json"])
    {
    }
    else if ([request.url hasSuffix:@"statuses/user_timeline.json"])
    {
    }
    else if ([request.url hasSuffix:@"statuses/update.json"])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:[NSString stringWithFormat:@"Post status \"%@\" failed!", postStatusText]
                                                           delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        
        DDLogVerbose(@"Post status failed with error : %@", error);
    }
    else if ([request.url hasSuffix:@"statuses/upload.json"])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:[NSString stringWithFormat:@"Post image status \"%@\" failed!", postImageStatusText]
                                                           delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];        
        DDLogVerbose(@"Post image status failed with error : %@", error);
    }
    
}

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)result
{
    if ([request.url hasSuffix:@"users/show.json"])
    {

    }
    else if ([request.url hasSuffix:@"statuses/user_timeline.json"])
    {

    }
    else if ([request.url hasSuffix:@"statuses/update.json"])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:[NSString stringWithFormat:@"Post status \"%@\" succeed!", [result objectForKey:@"text"]]
                                                           delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        
    }
    else if ([request.url hasSuffix:@"statuses/upload.json"])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                            message:[NSString stringWithFormat:@"Post image status \"%@\" succeed!", [result objectForKey:@"text"]]
                                                           delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        
    }
    
}

/////////////////////////////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
