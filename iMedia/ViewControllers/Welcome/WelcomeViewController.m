//
//  WelcomeViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-1.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WelcomeViewController.h"
#import "AppDelegate.h"
#import "Me.h"
#import <QuartzCore/QuartzCore.h>
#import "LoginSettingViewController.h"

@interface WelcomeViewController ()

@property(strong, nonatomic)UIButton *welcomeButton;
@property(strong, nonatomic)UILabel *welcomeLabel;
@property(strong, nonatomic)Me *me;

@end

@implementation WelcomeViewController
@synthesize welcomeButton;
@synthesize welcomeLabel;
@synthesize me;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.me = [self appDelegate].me;
        
    }
    return self;
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = T(@"欢迎");
    self.welcomeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.welcomeButton setFrame:CGRectMake(10, 160 , 300, 40)];
    [self.welcomeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.welcomeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.welcomeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.welcomeButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    //    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    
    self.welcomeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 80 , 300, 40)];
    [self.welcomeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.welcomeLabel setBackgroundColor:RGBCOLOR(234, 234, 234)];
    [self.welcomeLabel setNumberOfLines:0];
    [self.welcomeLabel setFont:[UIFont systemFontOfSize:16.0]];
    self.welcomeLabel.textColor = [UIColor grayColor];

//    if ([self.me.career length] ==0 ) {

    if ([self.me.gender isEqualToString:@""] || [self.me.displayName isEqualToString:@""] || [self.me.gender length] == 0 || [self.me.displayName length] == 0) {
        LoginSettingViewController *settingViewController = [[LoginSettingViewController alloc]initWithNibName:nil bundle:nil];
        [self.navigationController presentModalViewController:settingViewController animated:YES];
        
//        [self.welcomeButton setTitle:T(@"设置") forState:UIControlStateNormal];
//        [self.welcomeButton addTarget:self action:@selector(settingAction:) forControlEvents:UIControlEventTouchUpInside];
//        self.welcomeLabel.text = T(@"系统检测到你您还没有设置昵称和性别.");

    }else{
        [self.welcomeButton setTitle:T(@"欢迎来到春水堂") forState:UIControlStateNormal];
        [self.welcomeButton addTarget:self action:@selector(welcomeAction:) forControlEvents:UIControlEventTouchUpInside];
        self.welcomeLabel.text = T(@"中国情趣文化的倡导者");

    }

    [self.view addSubview:self.welcomeButton];
    [self.view addSubview:self.welcomeLabel];
	// Do any additional setup after loading the view.
}

////////////////////////////////////////////////////////////////////////////////////
#pragma mark - init the editing view
////////////////////////////////////////////////////////////////////////////////////


- (void)settingAction:(id)sender
{
    //
    LoginSettingViewController *settingViewController = [[LoginSettingViewController alloc]initWithNibName:nil bundle:nil];
    [self.navigationController presentModalViewController:settingViewController animated:YES];
}

- (void)welcomeAction:(id)sender
{
    [[self appDelegate] startMainSession];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
