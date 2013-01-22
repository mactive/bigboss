//
//  RegisterViewController.m
//  iMedia
//
//  Created by meng qian on 13-1-22.
//  Copyright (c) 2013年 Li Xiaosi. All rights reserved.
//

#import "RegisterViewController.h"
#import "AppDelegate.h"
#import "AppNetworkAPIClient.h"
#import <QuartzCore/QuartzCore.h>

@interface RegisterViewController ()

@property(strong, nonatomic)UIButton *barButton;
@property(strong,nonatomic) UITextField *usernameField;
@property(strong,nonatomic) UITextField *passwordField;
@property(strong, nonatomic)UIButton *loginButton;
@property(strong, nonatomic)UIImageView *logoImage;

@end

@implementation RegisterViewController
@synthesize barButton;
@synthesize usernameField;
@synthesize passwordField;
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

#define LOGO_HEIGHT 30
#define TEXTFIELD_Y 90
#define TEXTFIELD_X 25
#define TEXTFIELD_OFFSET 12
#define TEXTFIELD_WIDTH  270
#define TEXTFIELD_HEIGHT 40

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = T(@"注册");
    
    UIImageView *backgroundView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [backgroundView setImage:[UIImage imageNamed:@"login_bg.png"]];
    [self.view addSubview:backgroundView];
    
    self.logoImage = [[UIImageView alloc]initWithFrame:CGRectMake(60, TEXTFIELD_X, 200, 75)];
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
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.loginButton setFrame:CGRectMake(TEXTFIELD_X ,TEXTFIELD_Y+TEXTFEILD_HEIGHT*3+TEXTFIELD_HEIGHT-10, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.loginButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.loginButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.loginButton setTitle:T(@"注册") forState:UIControlStateNormal];
    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    [self.loginButton addTarget:self action:@selector(registerAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.logoImage];
    [self.view addSubview:self.usernameField];
    [self.view addSubview:self.passwordField];
    [self.view addSubview:self.loginButton];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
