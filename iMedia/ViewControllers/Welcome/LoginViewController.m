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
#import "DDLog.h"
#import <unistd.h>
#import <QuartzCore/QuartzCore.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface LoginViewController ()

@property(strong,nonatomic) UITextField *usernameField;
@property(strong,nonatomic) UITextField *passwordField;
@property(strong, nonatomic)UIButton *loginButton;
@property(strong, nonatomic)UIImageView *logoImage;
@property(strong, nonatomic)UIView *loginView;

@end

@implementation LoginViewController

@synthesize usernameField;
@synthesize passwordField;
@synthesize loginButton;
@synthesize logoImage;
@synthesize loginView;

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
    [self.passwordField resignFirstResponder];
    
    [self setField:usernameField forKey:kXMPPmyJID];
    [self setField:passwordField forKey:kXMPPmyPassword];
    
	
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	HUD.delegate = self;
	HUD.labelText = T(@"登录中");
    
    [[AppNetworkAPIClient sharedClient] loginWithUsername:self.usernameField.text andPassword:passwordField.text withBlock:^(id responseObject, NSError *error) {
        if (error == nil) {

            [HUD hide:YES];
            
            NSString* jid = [responseObject valueForKey:@"jid"];
            NSString *jPassword = [responseObject valueForKey:@"jpass"];
            NSString *guid= [[responseObject valueForKey:@"guid"] stringValue];
                        
            if (![[XMPPNetworkCenter sharedClient] connectWithUsername:jid andPassword:jPassword])
            {
                DDLogVerbose(@"%@: %@ cannot connect to XMPP server", THIS_FILE, THIS_METHOD);
            }            
            [[self appDelegate] createMeWithUsername:usernameField.text password:passwordField.text jid:jid jidPasswd:jPassword andGUID:guid withBlock:^(id responseObject, NSError *error) {
                
                [HUD hide:YES];
                
                if (responseObject != nil) {
                    WelcomeViewController *welcomeController = [[WelcomeViewController alloc]initWithNibName:nil bundle:nil];
                    [self.navigationController pushViewController:welcomeController animated:YES];
                } else {
                    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    HUD.delegate = self;
                    HUD.mode = MBProgressHUDModeText;
                    HUD.labelText = [responseObject valueForKey:@"status"];
                    [HUD hide:YES afterDelay:2];
                }
            }];
            
        } else {
            DDLogError(@"NSError received during login: %@", error);
            [HUD hide:YES];
            
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.delegate = self;
            HUD.mode = MBProgressHUDModeText;
            HUD.labelText = [responseObject valueForKey:@"status"];
            [HUD hide:YES afterDelay:2];
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
    
    self.logoImage = [[UIImageView alloc]initWithFrame:CGRectMake(87.5, 250,145, 75)];
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
    
    [self.loginView addSubview:self.usernameField];
    [self.loginView addSubview:self.passwordField];
    [self.view addSubview:self.loginView];
    [self.view addSubview:self.loginButton];
    [self.view addSubview:self.logoImage];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
