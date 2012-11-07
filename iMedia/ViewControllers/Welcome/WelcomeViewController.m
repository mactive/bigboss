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
@property(strong, nonatomic)UIImageView *welcomeTitleView;
@property(strong, nonatomic)Me *me;

@end

@implementation WelcomeViewController
@synthesize welcomeButton;
@synthesize welcomeTitleView;
@synthesize me;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.me = [self appDelegate].me;
        self.navigationItem.rightBarButtonItem = nil;
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
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320,417)];
    [backgroundView setImage:[UIImage imageNamed:@"welcome_bg.png"]];
    [self.view addSubview:backgroundView];
    
    self.welcomeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.welcomeButton setFrame:CGRectMake(80, 115, 160, 41)];
    [self.welcomeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [self.welcomeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.welcomeButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [self.welcomeButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    //    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    
    self.welcomeTitleView = [[UIImageView alloc]initWithFrame:CGRectMake(21, 32 , 278, 86)];
    [self.welcomeTitleView setImage:[UIImage imageNamed:@"welcome_title.png"]];

    if ([self.me.gender isEqualToString:@""] || [self.me.displayName isEqualToString:@""] || self.me.gender == nil || self.me.displayName == nil ) {
        LoginSettingViewController *settingViewController = [[LoginSettingViewController alloc]initWithNibName:nil bundle:nil];
        [self.navigationController presentModalViewController:settingViewController animated:NO];
    }
    
    [self.welcomeButton setTitle:T(@"春水堂") forState:UIControlStateNormal];
    [self.welcomeButton setBackgroundImage:[UIImage imageNamed:@"welcome_btn.png"] forState:UIControlStateNormal];
    [self.welcomeButton addTarget:self action:@selector(welcomeAction:) forControlEvents:UIControlEventTouchUpInside];
    

    
    [self.view addSubview:self.welcomeButton];
    [self.view addSubview:self.welcomeTitleView];
	// Do any additional setup after loading the view.
    
    [[self appDelegate] disableLeftBarButtonItemOnNavbar:YES];
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
    [[self appDelegate] disableLeftBarButtonItemOnNavbar:NO];
    [[self appDelegate] startMainSession];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
