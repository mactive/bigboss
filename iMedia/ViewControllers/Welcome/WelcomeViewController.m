//
//  WelcomeViewController.m
//  iMedia
//
//  Created by meng qian on 12-11-1.
//  Copyright (c) 2012年 Li Xiaosi. All rights reserved.
//

#import "WelcomeViewController.h"
#import "AppDelegate.h"

@interface WelcomeViewController ()

@property(strong, nonatomic)UIButton *welcomeButton;
@property(strong, nonatomic)UILabel *welcomeLabel;
@end

@implementation WelcomeViewController

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
    self.title = T(@"欢迎");
    self.welcomeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.welcomeButton setFrame:CGRectMake(10, 160 , 300, 40)];
    [self.welcomeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [self.welcomeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.welcomeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.welcomeButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [self.welcomeButton setTitle:T(@"欢迎来到大掌柜") forState:UIControlStateNormal];
    //    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"button_bg.png"] forState:UIControlStateNormal];
    [self.welcomeButton addTarget:self action:@selector(welcomeAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.welcomeLabel setFrame:CGRectMake(10, 80 , 300, 40)];
    self.welcomeLabel.backgroundColor = [UIColor clearColor];
    self.welcomeLabel.textColor = [UIColor grayColor];
    self.welcomeLabel.text = T(@"生意有困扰,大掌柜帮你搞.");


    [self.view addSubview:self.welcomeButton];
    [self.view addSubview:self.welcomeLabel];
    
    
	// Do any additional setup after loading the view.
}

- (void)welcomeAction:(id)sender
{
    [[self appDelegate] startMainSession];
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
