//
//  LoginViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-1.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "WelcomeViewController.h"
#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"
#import <unistd.h>
#import <QuartzCore/QuartzCore.h>
#import "ConvenienceMethods.h"
#import "MBProgressHUD.h"
#import "CuteData.h"
#import "LogEventConstants.h"

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
@property(strong, nonatomic)UIButton *loginButton;
@property(strong, nonatomic)UIImageView *logoImage;
@property(strong, nonatomic)UIView *loginView;
@property(strong, nonatomic) UILabel *userAgreementLabel;
@property(strong, nonatomic) id handle;

@end

@implementation LoginViewController

@synthesize usernameField;
@synthesize passwordField;
@synthesize loginButton;
@synthesize logoImage;
@synthesize loginView;
@synthesize userAgreementLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyUsername];
//    self.passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([passwordField isEqual:textField]) {
        [self loginAction:nil];
        return [textField resignFirstResponder];
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
            NSString *returnPassword = [responseObject valueForKey:@"pwd"];
            NSString *guid= [[responseObject valueForKey:@"guid"] stringValue];
            NSString *fulljid = [NSString stringWithFormat:@"%@/%@", barejid, guid];
                        
            if (![[XMPPNetworkCenter sharedClient] connectWithUsername:fulljid andPassword:jPassword])
            {
                DDLogVerbose(@"%@: %@ cannot connect to XMPP server", THIS_FILE, THIS_METHOD);
            }
            
            [[self appDelegate] createMeAndOtherOneTimeObjectsWithUsername:usernameField.text password:returnPassword jid:fulljid jidPasswd:jPassword andGUID:guid withBlock:^(id responseObject, NSError *error) {
            
                [HUD hide:YES];
                
                if (responseObject != nil) {
                    [XFox endTimedEvent:EVENT_LOGIN_TIMER withParameters:nil];
                    
                    WelcomeViewController *welcomeController = [[WelcomeViewController alloc]initWithNibName:nil bundle:nil];
                    [self.navigationController pushViewController:welcomeController animated:YES];
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
#define TEXTFIELD_OFFSET 15
#define TEXTFIELD_WIDTH 270
#define TEXTFIELD_HEIGHT 40


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = T(@"登录");
    
    self.loginView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 300,125)];
    [self.loginView setBackgroundColor:[UIColor whiteColor]];
    [self.loginView.layer setMasksToBounds:YES];
    [self.loginView.layer setCornerRadius:10.0];
    
    
    UIImageView *backgroundView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [backgroundView setImage:[UIImage imageNamed:@"login_bg.png"]];
    [self.view addSubview:backgroundView];
    
    self.logoImage = [[UIImageView alloc]initWithFrame:CGRectMake(87.5, 270, 145, 75)];
    [self.logoImage setImage:[UIImage imageNamed:@"login_intro_oyeah.png"]];


    self.usernameField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_OFFSET , TEXTFIELD_OFFSET, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.usernameField.font = [UIFont systemFontOfSize:18.0];
    self.usernameField.textColor = [UIColor grayColor];
    self.usernameField.delegate = self;
    self.usernameField.placeholder = T(@"用户名");
    self.usernameField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.usernameField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.usernameField.layer.borderWidth  = 1.0f;
    self.usernameField.layer.cornerRadius = 5.0f;
    self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.usernameField.textAlignment = UITextAlignmentCenter;
    
    
    self.passwordField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_OFFSET , TEXTFIELD_OFFSET*2 + TEXTFIELD_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.passwordField.font = [UIFont systemFontOfSize:18.0];
    self.passwordField.textColor = [UIColor grayColor];
    self.passwordField.delegate = self;
    self.passwordField.placeholder = T(@"密码");
    self.passwordField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.passwordField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.passwordField.layer.borderWidth  = 1.0f;
    self.passwordField.layer.cornerRadius = 5.0f;
    self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordField.textAlignment = UITextAlignmentCenter;

    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.loginButton setFrame:CGRectMake(TEXTFIELD_OFFSET +10 ,TEXTFEILD_HEIGHT*3+TEXTFIELD_HEIGHT-10, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.loginButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
//    [self.loginButton.titleLabel.layer setShadowColor:[[UIColor whiteColor] CGColor]];
//    [self.loginButton.titleLabel.layer setShadowOffset:CGSizeMake(0, 1)];
    [self.loginButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.loginButton setTitle:T(@"登录") forState:UIControlStateNormal];
    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.loginButton addTarget:self action:@selector(loginAction:) forControlEvents:UIControlEventTouchUpInside];
    
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
    
    self.userAgreementLabel = [[UILabel alloc]initWithFrame:CGRectMake(TEXTFIELD_OFFSET +25 ,TEXTFEILD_HEIGHT*5, TEXTFIELD_WIDTH*0.9, TEXTFIELD_HEIGHT)];
    self.userAgreementLabel.numberOfLines  = 2;
    self.userAgreementLabel.text = T(@"使用春水堂注册账户才可以登录. 登录即表示你接受芥末用户协议");
    self.userAgreementLabel.backgroundColor = [UIColor clearColor];
    self.userAgreementLabel.textAlignment = NSTextAlignmentLeft;
    self.userAgreementLabel.font = [UIFont systemFontOfSize:12.0f];
    self.userAgreementLabel.textColor = RGBCOLOR(66, 66, 66);
    
    [self.loginView addSubview:self.usernameField];
    [self.loginView addSubview:self.passwordField];
    [self.view addSubview:self.loginView];
    [self.view addSubview:self.loginButton];
    [self.view addSubview:self.logoImage];
    [self.view addSubview:self.userAgreementLabel];
    
	// Do any additional setup after loading the view.
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.handle = textField;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
