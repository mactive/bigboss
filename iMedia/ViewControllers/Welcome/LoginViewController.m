//
//  LoginViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-1.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "MainMenuViewController.h"
#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"
#import <unistd.h>
#import <QuartzCore/QuartzCore.h>
#import "ConvenienceMethods.h"
#import "MBProgressHUD.h"
#import "CuteData.h"
#import "LogEventConstants.h"
#import "WebViewController.h"
#import "RegisterViewController.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface LoginViewController ()

@property(strong,nonatomic) UITextField *usernameField;
@property(strong,nonatomic) UITextField *passwordField;
@property(strong, nonatomic) UIImageView *logoImage;
@property(strong, nonatomic) UILabel *userAgreementLabel;
@property(strong, nonatomic) id handle;
@property(strong, nonatomic) UIButton *barButton;
@property(strong, nonatomic) UIButton *userAgreementButton;
@property(strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation LoginViewController

@synthesize usernameField;
@synthesize passwordField;
@synthesize logoImage;
@synthesize userAgreementLabel;
@synthesize barButton;
@synthesize userAgreementButton;
@synthesize tapGestureRecognizer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_bg.png"] forState:UIControlStateNormal];
        [self.barButton setTitle:T(@"注册") forState:UIControlStateNormal];
        [self.barButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
        [self.barButton addTarget:self action:@selector(registerAction) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    if ([passwordField isEqual:textField]) {
        [self loginAction:nil];
        return [textField resignFirstResponder];
    }
    
    if (StringHasValue(self.passwordField.text) && StringHasValue(self.usernameField.text)) {
        if ([passwordField isEqual:textField]) {
            [self loginAction:nil];
            return [textField resignFirstResponder];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setField:(UITextField *)field forKey:(NSString *)key
{
    if (field.text != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:field.text forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)loginAction:(id)sender
{
    if (!StringHasValue(self.passwordField.text) || !StringHasValue(self.usernameField.text)) {
        return ;
    }
    if (self.handle != nil) {
        if ([self.handle isKindOfClass:[UITextField class]]) {
            [(UITextField *)self.handle resignFirstResponder];
        }
    }
    
    [self setField:usernameField forKey:kXMPPmyJID];
    [self setField:passwordField forKey:kXMPPmyPassword];
    
	
    MBProgressHUD * HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	HUD.removeFromSuperViewOnHide = YES;
	HUD.labelText = T(@"登录中");
    
    [XFox logEvent:EVENT_LOGIN_TIMER withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"success", @"status", @"", @"error", nil] timed:YES];
    
    [[AppNetworkAPIClient sharedClient] loginWithRetryCount:1 username:self.usernameField.text andPassword:passwordField.text withBlock:^(id responseObject, NSError *error) {
        if (responseObject!= nil &&  error == nil) {
            NSString* barejid = [responseObject valueForKey:@"jid"];
            NSString *jPassword = [responseObject valueForKey:@"jpass"];
            NSString *guid= [[responseObject valueForKey:@"guid"] stringValue];
            NSString *fulljid = [NSString stringWithFormat:@"%@/%@", barejid, guid];
                        
            if (![[XMPPNetworkCenter sharedClient] connectWithUsername:fulljid andPassword:jPassword])
            {
                DDLogVerbose(@"%@: %@ cannot connect to XMPP server", THIS_FILE, THIS_METHOD);
            }
            
            [[self appDelegate] createMeAndOtherOneTimeObjectsWithUsername:usernameField.text password:passwordField.text jid:fulljid jidPasswd:jPassword andGUID:guid withBlock:^(id responseObject, NSError *error) {
            
                [HUD hide:YES];
                
                if (responseObject != nil) {
                    [XFox endTimedEvent:EVENT_LOGIN_TIMER withParameters:nil];
                    
                    // 进入mainmenu
                    [[self appDelegate] startMainSession];

                } else {
                    [XFox endTimedEvent:EVENT_LOGIN_TIMER withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"failure", @"status", error, @"error", nil]];
                    [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:[responseObject valueForKey:@"status"] andHideAfterDelay:2];
                }
            }];
            
        } else {
            [XFox endTimedEvent:EVENT_LOGIN_TIMER withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"failure", @"status", error, @"error", nil]];
            
            DDLogError(@"NSError received during login: %@", error);
            [HUD hide:YES];
            
            MBProgressHUD *HUD2 = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD2.removeFromSuperViewOnHide = YES;
            HUD2.mode = MBProgressHUDModeText;
            NSString * status = [responseObject valueForKey:@"status"];
            if ([status isEqualToString:@"banned"]) {
                HUD2.labelText = T(@"你的帐号已被封");
                HUD2.detailsLabelText = T(@"请联系4006780365");
            } else if ([status isEqualToString:@"wrongusername"] || [status isEqualToString:@"wrongpassword"]) {
                HUD2.labelText = T(@"用户名或密码错误");
            } else {
                HUD2.labelText = T(@"系统维护，请稍后重试或联系客服");
            }
            [HUD2 hide:YES afterDelay:2];
        }
        
    }];
    
    
}


#define LOGO_HEIGHT 30
#define TEXTFIELD_Y 90
#define TEXTFIELD_X 25
#define TEXTFIELD_OFFSET 12
#define TEXTFIELD_WIDTH  270
#define TEXTFIELD_HEIGHT 40


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = T(@"登录");
    
    UIImageView *backgroundView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [backgroundView setImage:[UIImage imageNamed:@"login_bg.png"]];
    [self.view addSubview:backgroundView];
    
    self.logoImage = [[UIImageView alloc]initWithFrame:CGRectMake(60, 131, 200, 75)];
    [self.logoImage setImage:[UIImage imageNamed:@"logo.png"]];


    self.usernameField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X , TEXTFIELD_Y + TEXTFIELD_OFFSET, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.usernameField.font = [UIFont systemFontOfSize:18.0];
    self.usernameField.textColor = [UIColor grayColor];
    self.usernameField.delegate = self;
    self.usernameField.placeholder = T(@"邮箱");
    self.usernameField.backgroundColor = TEXTFIELD_BGCOLOR;
    self.usernameField.layer.borderColor = [TEXTFIELD_BORDERCOLOR CGColor];
    self.usernameField.layer.borderWidth  = 1.0f;
    self.usernameField.layer.cornerRadius = 5.0f;
    self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.usernameField.textAlignment = UITextAlignmentCenter;
    
    
    self.passwordField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X , TEXTFIELD_Y + TEXTFIELD_OFFSET*2 + TEXTFIELD_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.passwordField.font = [UIFont systemFontOfSize:18.0];
    self.passwordField.textColor = [UIColor grayColor];
    self.passwordField.delegate = self;
    self.passwordField.placeholder = T(@"密码");
    self.passwordField.backgroundColor = TEXTFIELD_BGCOLOR;
    self.passwordField.layer.borderColor = [TEXTFIELD_BORDERCOLOR CGColor];
    self.passwordField.layer.borderWidth  = 1.0f;
    self.passwordField.layer.cornerRadius = 5.0f;
    self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordField.textAlignment = UITextAlignmentCenter;
    
    // set thekeyboard type and color and first letter
    self.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
    self.usernameField.returnKeyType = UIReturnKeyNext;
    self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.passwordField.keyboardType = UIKeyboardTypeDefault;
    self.passwordField.returnKeyType = UIReturnKeyGo;
    self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordField.secureTextEntry = YES;
    
    self.userAgreementLabel = [[UILabel alloc]initWithFrame:CGRectMake(TEXTFIELD_X ,TEXTFEILD_HEIGHT*5, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.userAgreementLabel.numberOfLines  = 1;
    self.userAgreementLabel.text = T(@"请使用大掌柜注册账户登录. 登录即表示你接受");
    self.userAgreementLabel.backgroundColor = [UIColor clearColor];
    self.userAgreementLabel.textAlignment = NSTextAlignmentCenter;
    self.userAgreementLabel.font = [UIFont systemFontOfSize:12.0f];
    self.userAgreementLabel.textColor = RGBCOLOR(66, 66, 66);
    
    // 用户协议
    self.userAgreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.userAgreementButton.enabled = YES;
    [self.userAgreementButton setFrame:CGRectMake(TEXTFIELD_X ,TEXTFEILD_HEIGHT*5.5, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.userAgreementButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0]];
    [self.userAgreementButton setTitleColor:BIGBOSS_BLUE forState:UIControlStateNormal];
    [self.userAgreementButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.userAgreementButton setTitle:T(@"大掌柜协议") forState:UIControlStateNormal];
    [self.userAgreementButton addTarget:self action:@selector(userAgreementAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.userAgreementButton];
    [self.view addSubview:self.usernameField];
    [self.view addSubview:self.passwordField];
    [self.view addSubview:self.logoImage];
    [self.view addSubview:self.userAgreementLabel];
    
	// Do any additional setup after loading the view.
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
    
    // animation
    [self.usernameField setAlpha:0.0f];
    [self.passwordField setAlpha:0.0f];
    [self.userAgreementLabel setAlpha:0.0f];
    [self.userAgreementButton setAlpha:0.0f];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyUsername];
    //    self.passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    UIKeyboardNotificationsObserve();
    
    [UIView animateWithDuration:0.8 animations:^{
        [self.logoImage setFrame:CGRectMake(60, TEXTFIELD_OFFSET, 200, 75)];
    }];
    
    [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationCurveLinear animations:^{
        [self.usernameField setAlpha:1.0f];
        [self.passwordField setAlpha:1.0f];
        [self.userAgreementLabel setAlpha:1.0f];
        [self.userAgreementButton setAlpha:1.0f];
    } completion:^(BOOL finished) {
        //
    }];
    
    

}


// keyboard hide and show 
- (void)keyboardWillShow:(NSNotification*)notification
{
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.handle = textField;
}

// actions

- (void)registerAction
{
    [(UITextField *)self.handle resignFirstResponder];
    // 清空输入框
    self.passwordField.text = @"";
    
    RegisterViewController *controller = [[RegisterViewController alloc] initWithNibName:nil bundle:nil];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentModalViewController: navController animated: YES];
    

}


- (void)userAgreementAction
{
    // jump to userAgreement
    WebViewController *controller = [[WebViewController alloc]initWithNibName:nil bundle:nil];
    [controller setHidesBottomBarWhenPushed:YES];
    controller.titleString = T(@"用户协议");
    controller.urlString = @"http://www.wingedstone.com/user_agreement.html";
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)handleTap:(UITapGestureRecognizer *)paramSender
{
    [(UITextField *)self.handle resignFirstResponder];
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
