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
#import "SBJson.h"
#import "DDLog.h"
#import <unistd.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface LoginViewController ()

@property(strong, nonatomic)UILabel *usernameLabel;
@property(strong, nonatomic)UILabel *passwordLabel;
@property(strong, nonatomic)UIButton *loginButton;
@property(strong, nonatomic)UIImageView *logoImage;

@end

@implementation LoginViewController

@synthesize usernameField;
@synthesize passwordField;
@synthesize usernameLabel;
@synthesize passwordLabel;
@synthesize loginButton;
@synthesize logoImage;

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
    self.passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
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
            [[self appDelegate] createMeWithUsername:usernameField.text password:passwordField.text jid:jid jidPasswd:jPassword andGUID:guid];
            
            WelcomeViewController *welcomeController = [[WelcomeViewController alloc]initWithNibName:nil bundle:nil];
            [self.navigationController pushViewController:welcomeController animated:YES];
            
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
#define LEFT_OFFSET 20
#define LABEL_WIDTH 120
#define LABEL_HEIGHT 50
#define TEXTFIELD_OFFSET 120
#define TEXTFIELD_WIDTH 180


- (void)viewDidLoad
{
    [super viewDidLoad];
    
        
    self.logoImage = [[UIImageView alloc]initWithFrame:CGRectMake(50, 10,220, 50)];
    [self.logoImage setImage:[UIImage imageNamed:@"logo.png"]];
    
    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_OFFSET, LABEL_HEIGHT+LOGO_HEIGHT, LABEL_WIDTH, 30)];
    self.usernameLabel.text = T(@"用户名");
    self.usernameLabel.backgroundColor = [UIColor clearColor];

    self.passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_OFFSET, LABEL_HEIGHT*2+LOGO_HEIGHT, LABEL_WIDTH, 30)];
    self.passwordLabel.text = T(@"密码");
    self.passwordLabel.backgroundColor = [UIColor clearColor];

    
    self.usernameField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_OFFSET , LABEL_HEIGHT+LOGO_HEIGHT, TEXTFIELD_WIDTH, 30)];
    self.usernameField.font = [UIFont systemFontOfSize:20.0];
    [self.usernameField setBorderStyle:UITextBorderStyleRoundedRect];
    self.usernameField.textColor = [UIColor grayColor];
    self.usernameField.backgroundColor = [UIColor whiteColor];
    self.usernameField.delegate = self;
    
    self.passwordField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_OFFSET , LABEL_HEIGHT*2+LOGO_HEIGHT, TEXTFIELD_WIDTH, 30)];
    self.passwordField.font = [UIFont systemFontOfSize:20.0];
    [self.passwordField setBorderStyle:UITextBorderStyleRoundedRect];
    self.passwordField.textColor = [UIColor grayColor];
    self.passwordField.backgroundColor = [UIColor whiteColor];
    [self.passwordField setSecureTextEntry:YES];
    self.passwordField.delegate = self;
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.loginButton setFrame:CGRectMake(80 , LABEL_HEIGHT*3+20, TEXTFIELD_WIDTH, 30)];
    [self.loginButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.loginButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.loginButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.loginButton setTitle:T(@"登录") forState:UIControlStateNormal];
//    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    [self.loginButton addTarget:self action:@selector(loginAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // set thekeyboard type and color and first letter
    
    self.usernameField.keyboardType = UIKeyboardTypeURL;
    self.usernameField.returnKeyType = UIReturnKeyNext;
    self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    self.passwordField.keyboardType = UIKeyboardTypeDefault;
    self.passwordField.returnKeyType = UIReturnKeyGo;
    self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    
    [self.view addSubview:self.usernameLabel];
    [self.view addSubview:self.usernameField];
    [self.view addSubview:self.passwordLabel];
    [self.view addSubview:self.passwordField];
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
