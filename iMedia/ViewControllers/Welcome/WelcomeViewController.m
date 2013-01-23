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

//@property(strong, nonatomic)UIButton *welcomeButton;
//@property(strong, nonatomic)UIImageView *welcomeTitleView;
@property(strong, nonatomic)Me *me;

@end

@implementation WelcomeViewController
//@synthesize welcomeButton;
//@synthesize welcomeTitleView;
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
    
//    Do any additional setup after loading the view.
    if ([self.me.gender isEqualToString:@""] || [self.me.displayName isEqualToString:@""] || self.me.gender == nil || self.me.displayName == nil ) {
        LoginSettingViewController *settingViewController = [[LoginSettingViewController alloc]initWithNibName:nil bundle:nil];
        [self.navigationController presentModalViewController:settingViewController animated:NO];
    }else{
        [self doneGenderNameAction];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneGenderNameAction) name:@"doneGenderName" object:nil];


    [[self appDelegate] disableLeftBarButtonItemOnNavbar:YES];
}


////////////////////////////////////////////////////////////////////////////////////
#pragma mark - init the editing view
////////////////////////////////////////////////////////////////////////////////////


- (void)doneGenderNameAction
{
    [self performSelector:@selector(welcomeAction) withObject:nil afterDelay:2];
}

- (void)welcomeAction
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
