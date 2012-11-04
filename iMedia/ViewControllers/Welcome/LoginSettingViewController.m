//
//  LoginSettingViewController.m
//  iMedia
//
//  Created by mac on 12-11-4.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "LoginSettingViewController.h"
#import "AppDelegate.h"
#import "Me.h"
#import <QuartzCore/QuartzCore.h>


@interface LoginSettingViewController ()


@property(strong, nonatomic)UILabel *displayNameLabel;
@property(strong, nonatomic)UILabel *genderLabel;
@property(strong, nonatomic)UITextField *displayNameField;
@property(strong, nonatomic)UIButton *genderButton;
@property(strong, nonatomic)UIPickerView *genderPicker;
@property(strong, nonatomic)UIButton *welcomeButton;

@end

@implementation LoginSettingViewController

@synthesize displayNameLabel;
@synthesize genderLabel;
@synthesize displayNameField;
@synthesize genderButton;
@synthesize genderPicker;
@synthesize welcomeButton;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BGCOLOR;
	// Do any additional setup after loading the view.
    self.title = T(@"设置初始信息");
    
    self.displayNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 20, 120 , 30)];
    [self.displayNameLabel setBackgroundColor:[UIColor clearColor]];
    [self.displayNameLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.displayNameLabel setTextColor:[UIColor grayColor]];
    self.displayNameLabel.shadowColor = [UIColor whiteColor];
    self.displayNameLabel.shadowOffset = CGSizeMake(0, 1);
    self.displayNameLabel.text = T(@"姓名");
    self.displayNameLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.displayNameLabel];
    
    self.genderLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 60, 120 , 30)];
    [self.genderLabel setBackgroundColor:[UIColor clearColor]];
    [self.genderLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [self.genderLabel setTextColor:[UIColor grayColor]];
    self.genderLabel.shadowColor = [UIColor whiteColor];
    self.genderLabel.shadowOffset = CGSizeMake(0, 1);
    self.genderLabel.text = T(@"性别");
    self.genderLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.genderLabel];
    
    
    self.welcomeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.welcomeButton setFrame:CGRectMake(10, 160 , 300, 40)];
    [self.welcomeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.welcomeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.welcomeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.welcomeButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    
    [self.welcomeButton setTitle:T(@"欢迎来到大掌柜") forState:UIControlStateNormal];
    [self.welcomeButton addTarget:self action:@selector(welcomeAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.welcomeButton];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
