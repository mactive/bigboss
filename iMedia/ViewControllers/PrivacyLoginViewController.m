//
//  PrivacyLoginViewController.m
//  jiemo
//
//  Created by meng qian on 12-12-20.
//  Copyright (c) 2012年 oyeah. All rights reserved.
//

#import "PrivacyLoginViewController.h"
#import "MBProgressHUD.h"
#import "ConvenienceMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "Me.h"
#import "ConfigSetting.h"
#import "AppNetworkAPIClient.h"
#import "XMPPNetworkCenter.h"
#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface PrivacyLoginViewController ()<UITextFieldDelegate>

@property(nonatomic,strong)UILabel *noticeLabel;
@property(strong,nonatomic) UITextField *passField;
@property(strong, nonatomic) UIButton *doneButton;
@property(strong, nonatomic) UIButton *forgetButton;
@property(strong, nonatomic) NSString *state;

@end

@implementation PrivacyLoginViewController
@synthesize noticeLabel;
@synthesize passField;
@synthesize doneButton;
@synthesize forgetButton;
@synthesize state;

#define LOGO_HEIGHT 30
#define TEXTFIELD_X_OFFSET 25
#define TEXTFIELD_Y_OFFSET 15
#define TEXTFIELD_WIDTH 270
#define TEXTFIELD_HEIGHT 40
#define PASS_MAX_LENGTH 4

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = BGCOLOR;
	// Do any additional setup after loading the view.
    
    // noticelabel
    self.noticeLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 10, 260, 50)];
    [self.noticeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.noticeLabel setBackgroundColor:[UIColor clearColor]];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:14.0]];
    self.noticeLabel.textColor = RGBCOLOR(195, 70, 21);
    self.noticeLabel.shadowColor = [UIColor whiteColor];
    self.noticeLabel.numberOfLines = 0;
    self.noticeLabel.shadowOffset = CGSizeMake(0, 1);
    
    // passfield
    self.passField = [[UITextField alloc]initWithFrame:CGRectMake(TEXTFIELD_X_OFFSET , TEXTFIELD_Y_OFFSET  + TEXTFEILD_HEIGHT+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    self.passField.font = [UIFont systemFontOfSize:18.0];
    self.passField.textColor = [UIColor grayColor];
    self.passField.delegate = self;
    self.passField.backgroundColor = RGBCOLOR(240, 240, 240);
    self.passField.layer.borderColor = [RGBCOLOR(147, 150, 157) CGColor];
    self.passField.layer.borderWidth  = 1.0f;
    self.passField.layer.cornerRadius = 5.0f;
    self.passField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passField.textAlignment = UITextAlignmentCenter;
    self.passField.keyboardType = UIKeyboardTypeNumberPad;
    
    // doneButton
    self.doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.doneButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*2+TEXTFIELD_HEIGHT*2+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.doneButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.doneButton setTitle:T(@"确定") forState:UIControlStateNormal];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"button_cancel_bg.png"] forState:UIControlStateNormal];
    
    // forgetButton
    self.forgetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.forgetButton setFrame:CGRectMake(TEXTFIELD_X_OFFSET ,TEXTFIELD_Y_OFFSET*3+TEXTFIELD_HEIGHT*3+LOGO_HEIGHT, TEXTFIELD_WIDTH, TEXTFIELD_HEIGHT)];
    [self.forgetButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
    [self.forgetButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.forgetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.forgetButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.forgetButton setTitle:T(@"忘记密码") forState:UIControlStateNormal];
    
    [self.view addSubview:self.noticeLabel];
    [self.view addSubview:self.passField];
    [self.view addSubview:self.doneButton];
    [self.view addSubview:self.forgetButton];
    [self initInterface];
}

- (void)initInterface{
    [self.doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.forgetButton addTarget:self action:@selector(forgetButtonAction) forControlEvents:UIControlEventTouchUpInside];

    self.noticeLabel.text = T(@"请输入你设置的4位隐私密码");
    self.passField.placeholder = T(@"你的4位密码");
    self.passField.text = @"";
    DDLogVerbose(@"privacyPass %@ ", [self appDelegate].me.privacyPass);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.state isEqualToString:@"forgetRequest"]) {
        [self.doneButton removeTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }else if ([self.state isEqualToString:@"doneButtonAction"]){
        [self.doneButton removeTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }else if ([self.state isEqualToString:@"forgetButtonAction"]){
        [self.doneButton removeTarget:self action:@selector(forgetRequest) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)forgetButtonAction
{
    self.passField.text = @"";
    self.passField.placeholder = T(@"大掌柜登录密码");
    self.noticeLabel.text = T(@"请输入你的大掌柜登录密码,如果忘记可以去大掌柜网站找回密码");
    [self.doneButton removeTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton addTarget:self action:@selector(forgetRequest) forControlEvents:UIControlEventTouchUpInside];
    self.state = @"forgetButtonAction";

}

- (void)forgetRequest
{
    [self.passField resignFirstResponder];
    [self.doneButton removeTarget:self action:@selector(forgetRequest) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.state = @"forgetRequest";
    
    MBProgressHUD * HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	HUD.removeFromSuperViewOnHide = YES;
	HUD.labelText = T(@"登录中");
    
    DDLogVerbose(@"text %@ %@",[self appDelegate].me.username, self.passField.text);
    
    // 设置 isLoggedIn 否则一天内不会重复登陆
    [AppNetworkAPIClient sharedClient].isLoggedIn = NO;
    [[AppNetworkAPIClient sharedClient]loginWithRetryCount:1 username:[self appDelegate].me.username andPassword:self.passField.text withBlock:^(id responseObject, NSError *error) {
        if (responseObject!= nil &&  error == nil) {
            [HUD hide:YES];

            NSString *returnPassword = [responseObject valueForKey:@"pwd"];
            NSString *guid= [[responseObject valueForKey:@"guid"] stringValue];

            DDLogVerbose(@"%@",responseObject);
            
            if ([[self appDelegate].me.guid isEqualToString:guid] && StringHasValue(returnPassword)) {
                [self appDelegate].me.password  = returnPassword;
            }
            [[self appDelegate] transformPrivacyLogin];
            
        }else{
            [HUD hide:YES];

            [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"登录密码错误") andHideAfterDelay:2];
        }
    }];

//    if ([[self appDelegate].me.password isEqualToString:self.passField.text]) {
//        [[self appDelegate] transformPrivacyLogin];
//    }else{
//        [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"密码错误") andHideAfterDelay:2];
//    }
}

- (void)doneButtonAction
{
//    DDLogVerbose(@"%@ %@",self.passField.text,[self appDelegate].me.privacyPass);
    [self.passField resignFirstResponder];
    self.state = @"doneButtonAction";
    
    if ([[self appDelegate].me.privacyPass isEqualToString:self.passField.text]) {
        [[self appDelegate] transformPrivacyLogin];
    }else{
        [ConvenienceMethods showHUDAddedTo:self.view animated:YES text:T(@"隐私密码错误") andHideAfterDelay:2];
    }
}


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
