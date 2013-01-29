//
//  FunctionListViewController.m
//  iMedia
//
//  Created by Xiaosi Li on 10/29/12.
//  Copyright (c) 2012 Li Xiaosi. All rights reserved.
//

#import "FunctionListViewController.h"
#import "ShakeDashboardViewController.h"
#import "XMPPNetworkCenter.h"
#import "AppNetworkAPIClient.h"
#import "AppDelegate.h" 
#import "FriendRequestListViewController.h"
#import "FriendRequest.h"
#import "ModelHelper.h"
#import "MetroButton.h"
#import "ChannelListViewController.h"

#import "DDLog.h"
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

@interface FunctionListViewController ()

@property(nonatomic, strong) UIView *settingView;
@property(nonatomic, strong) NSArray *settingTitleArray;
@property(nonatomic, strong) NSArray *settingDescArray;
@property(nonatomic, strong) UIButton *barButton;

@end

@implementation FunctionListViewController

@synthesize settingView;
@synthesize settingDescArray;
@synthesize settingTitleArray;
@synthesize managedObjectContext;
@synthesize barButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.barButton = [[UIButton alloc] init];
        self.barButton.frame=CGRectMake(0, 0, 50, 29);
        [self.barButton setBackgroundImage:[UIImage imageNamed: @"barbutton_mainmenu.png"] forState:UIControlStateNormal];
        [self.barButton addTarget:self action:@selector(mainMenuAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setHidesBackButton:YES];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.barButton];
    }
    return self;
}

- (void)mainMenuAction
{
    [self.navigationController popViewControllerAnimated:NO];
}

#define VIEW_ALBUM_OFFSET 10
#define VIEW_ALBUM_WIDTH 300
#define VIEW_ALBUM_HEIGHT 150
#define COUNT_PER_LINE 1
#define Y_OFFEST 16

- (CGRect)calcRect:(NSInteger)index
{
    CGFloat x = VIEW_ALBUM_OFFSET * (index % COUNT_PER_LINE * 1 + 1) + VIEW_ALBUM_WIDTH * (index % COUNT_PER_LINE) ;
    CGFloat y = VIEW_ALBUM_OFFSET * (floor(index / COUNT_PER_LINE) * 1 + 1) + VIEW_ALBUM_HEIGHT * floor(index / COUNT_PER_LINE);
    return  CGRectMake( x, y+Y_OFFEST, VIEW_ALBUM_WIDTH, VIEW_ALBUM_HEIGHT);
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.settingTitleArray = [[NSArray alloc] initWithObjects:@"摇一摇",@"情趣研究院", nil]; //@"打招呼的人", 
    self.view.backgroundColor = BGCOLOR;
    [self.view addSubview:self.settingView];
    
    for (int index = 0; index <[self.settingTitleArray count]; index++) {
        MetroButton *button = [[MetroButton alloc]initWithFrame:[self calcRect:index]];
        NSString *title = [self.settingTitleArray objectAtIndex:index];
        NSString *image = [NSString stringWithFormat:@"metro_icon_%d.png",(index+3)];
        [button initMetroButton:[UIImage imageNamed:image] andText:title andIndex:index];
        
//        if (index == 0) {
//            [button addTarget:self action:@selector(sayhiAction) forControlEvents:UIControlEventTouchUpInside];
//        }
        if (index == 0) {
            [button addTarget:self action:@selector(shakeAction) forControlEvents:UIControlEventTouchUpInside];
        }
        if (index == 1) {
            [button addTarget:self action:@selector(channelListAction) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:button];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - actions
////////////////////////////////////////////////////////////////////////////////////////
- (void)sayhiAction
{
   //
}

- (void)shakeAction
{
    ShakeDashboardViewController *shakeDashboardViewController = [[ShakeDashboardViewController alloc] initWithNibName:nil bundle:nil];
//    [self.navigationController setHidesBottomBarWhenPushed:YES];
    shakeDashboardViewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:shakeDashboardViewController animated:YES];
}

- (void)channelListAction
{
    ChannelListViewController *controller = [[ChannelListViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];
}


- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
